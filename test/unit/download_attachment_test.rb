# frozen_string_literal: true

# Redmine MCP plugin
#
# Copyright (C) 2026 RK Team
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <https://www.gnu.org/licenses/>.

require File.expand_path('../test_helper', __dir__)

class RedmineMcpDownloadAttachmentTest < RedmineMcpTestCase
  def setup
    super
    set_tmp_attachments_directory
    @admin = User.find(1)
    @member = User.find(2)
  end

  test 'download_attachment returns content_base64 for issue attachment' do
    content = "PK\x03\x04fake-docx-zip-body"
    attachment = create_issue_attachment(content: content, filename: 'spec.docx', content_type: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document')
    downloads_before = attachment.downloads

    payload = invoke_mcp_tool('download_attachment', user: @admin, args: {attachment_id: attachment.id})

    assert payload[:ok], "expected ok payload, got: #{payload.inspect}"
    assert_equal attachment.id, payload.dig(:data, :attachment_id)
    assert_equal 'spec.docx', payload.dig(:data, :filename)
    assert_equal attachment.filesize, payload.dig(:data, :size)
    decoded = Base64.strict_decode64(payload.dig(:data, :content_base64))

    assert_equal content, decoded
    assert decoded.start_with?('PK')
    assert_equal downloads_before, attachment.reload.downloads
    assert_nil payload.dig(:data, :diskfile)
    assert_not_includes payload.to_json, Attachment.storage_path.to_s
  end

  test 'download_attachment returns FILE_TOO_LARGE when filesize exceeds limit' do
    attachment = create_issue_attachment(
      content: 'small',
      filename: 'big.bin',
      content_type: RedmineMcp::Core::Helpers::DEFAULT_CONTENT_TYPE
    )
    attachment.update_column(:filesize, RedmineMcp::Core::Helpers::MAX_DOWNLOAD_BYTES + 1)
    File.binwrite(attachment.diskfile, 'x' * (RedmineMcp::Core::Helpers::MAX_DOWNLOAD_BYTES + 1))

    payload = invoke_mcp_tool('download_attachment', user: @admin, args: {attachment_id: attachment.id})

    assert_equal false, payload[:ok]
    assert_equal 'FILE_TOO_LARGE', payload.dig(:error, :code)
    assert_equal RedmineMcp::Core::Helpers::MAX_DOWNLOAD_BYTES + 1, payload.dig(:error, :details, :size)
    assert_equal RedmineMcp::Core::Helpers::MAX_DOWNLOAD_BYTES, payload.dig(:error, :details, :max_bytes)
  end

  test 'download_attachment returns FILE_TOO_LARGE when disk file exceeds limit despite small metadata' do
    attachment = create_issue_attachment(
      content: 'tiny',
      filename: 'mismatch.bin',
      content_type: RedmineMcp::Core::Helpers::DEFAULT_CONTENT_TYPE
    )
    oversized = RedmineMcp::Core::Helpers::MAX_DOWNLOAD_BYTES + 1
    File.binwrite(attachment.diskfile, 'x' * oversized)
    attachment.update_column(:filesize, 4)

    payload = invoke_mcp_tool('download_attachment', user: @admin, args: {attachment_id: attachment.id})

    assert_equal false, payload[:ok]
    assert_equal 'FILE_TOO_LARGE', payload.dig(:error, :code)
    assert_equal oversized, payload.dig(:error, :details, :size)
    assert_equal RedmineMcp::Core::Helpers::MAX_DOWNLOAD_BYTES, payload.dig(:error, :details, :max_bytes)
  end

  test 'download_attachment returns actual content size when metadata differs' do
    attachment = create_issue_attachment(
      content: 'hello',
      filename: 'size.bin',
      content_type: RedmineMcp::Core::Helpers::DEFAULT_CONTENT_TYPE
    )
    File.binwrite(attachment.diskfile, 'hello-world')
    attachment.update_column(:filesize, 1)

    payload = invoke_mcp_tool('download_attachment', user: @admin, args: {attachment_id: attachment.id})

    assert payload[:ok], "expected ok payload, got: #{payload.inspect}"
    assert_equal 11, payload.dig(:data, :size)
    assert_equal 'hello-world', Base64.strict_decode64(payload.dig(:data, :content_base64))
  end

  test 'download_attachment denies invisible attachment' do
    attachment = Attachment.create!(
      file: mock_file(original_filename: 'orphan.txt', content_type: 'text/plain', content: 'secret'),
      author: @admin
    )

    payload = invoke_mcp_tool('download_attachment', user: @member, args: {attachment_id: attachment.id})

    assert_equal false, payload[:ok]
    assert_equal 'NOT_FOUND', payload.dig(:error, :code)
  end

  test 'download_attachment returns NOT_FOUND for missing id' do
    payload = invoke_mcp_tool('download_attachment', user: @admin, args: {attachment_id: 99_999})

    assert_equal false, payload[:ok]
    assert_equal 'NOT_FOUND', payload.dig(:error, :code)
  end

  test 'download_attachment falls back to octet-stream when content_type blank' do
    attachment = create_issue_attachment(content: 'plain', filename: 'no-mime.bin', content_type: 'text/plain')
    attachment.update_column(:content_type, nil)

    payload = invoke_mcp_tool('download_attachment', user: @admin, args: {attachment_id: attachment.id})

    assert payload[:ok], "expected ok payload, got: #{payload.inspect}"
    assert_equal RedmineMcp::Core::Helpers::DEFAULT_CONTENT_TYPE, payload.dig(:data, :content_type)
  end

  def create_issue_attachment(content:, filename:, content_type:)
    upload_io = RedmineMcp::Core::Helpers.build_upload_io(content, filename: filename, content_type: content_type)
    attachment = Attachment.new(container: Issue.find(1), author: @admin)
    attachment.file = upload_io
    attachment.filename = filename
    attachment.save!
    attachment
  end
end
