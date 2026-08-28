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

class RedmineMcpToolsContractTest < RedmineMcpTestCase
  SNAPSHOT_PATH = File.expand_path('../fixtures/tools_contract_snapshot.json', __dir__)

  test 'tools contract matches snapshot' do
    assert_path_exists SNAPSHOT_PATH, "missing contract snapshot: #{SNAPSHOT_PATH}"

    current = tool_contract_snapshot
    expected = JSON.parse(File.read(SNAPSHOT_PATH))

    assert_equal expected.keys.sort, current.keys.sort, 'tool set changed'
    current.each do |name, metadata|
      assert_equal expected.fetch(name), metadata, "contract changed for #{name}"
    end
  end

  test 'read only tools are marked idempotent' do
    all_mcp_tools.select { |tool| tool.annotations[:read_only_hint] }.each do |tool|
      assert tool.annotations[:idempotent_hint], "#{tool.full_name} should be idempotent"
    end
  end
end
