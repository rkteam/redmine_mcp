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

class RedmineMcpCapabilityNormalizerTest < RedmineMcpTestCase
  AVOID_SEARCH_BY_ISSUE_ID = 'search by issue ID'

  test 'normalize available false' do
    result = RedmineMcp::CapabilityNormalizer.normalize(
      {available: false, tool: 'x'},
      plugin_id: :test,
      group: :issue_search,
      mode: :semantic
    )

    assert_equal({available: false}, result)
  end

  test 'normalize available true with full contract' do
    result = RedmineMcp::CapabilityNormalizer.normalize(
      {
        available: true,
        tool: 'advanced_search_semantic_search_issues',
        provider: 'advanced_search',
        use_when: ['search by meaning'],
        avoid_when: [AVOID_SEARCH_BY_ISSUE_ID]
      },
      plugin_id: :advanced_search,
      group: :issue_search,
      mode: :semantic
    )

    assert(result[:available])
    assert_equal('advanced_search_semantic_search_issues', result[:tool])
    assert_equal('advanced_search', result[:provider])
    assert_equal(['search by meaning'], result[:use_when])
    assert_equal([AVOID_SEARCH_BY_ISSUE_ID], result[:avoid_when])
  end

  test 'normalize available true without required fields falls back' do
    result = RedmineMcp::CapabilityNormalizer.normalize(
      {available: true, tool: 'advanced_search_semantic_search_issues'},
      plugin_id: :advanced_search,
      group: :issue_search,
      mode: :semantic
    )

    assert_equal({available: false}, result)
  end

  test 'normalize available true with empty use_when falls back' do
    result = RedmineMcp::CapabilityNormalizer.normalize(
      {
        available: true,
        tool: 'advanced_search_semantic_search_issues',
        provider: 'advanced_search',
        use_when: [],
        avoid_when: [AVOID_SEARCH_BY_ISSUE_ID]
      },
      plugin_id: :advanced_search,
      group: :issue_search,
      mode: :semantic
    )

    assert_equal({available: false}, result)
  end

  test 'apply_capabilities replaces incomplete provider with unavailable' do
    registry = RedmineMcp::Registry.instance
    capabilities = registry.instance_variable_get(:@capabilities)
    key = [:issue_search, :semantic]
    previous = capabilities[key]
    modes = {semantic: {available: false}}

    registry.register_capability(
      plugin_id: :test_capability_incomplete,
      group: :issue_search,
      mode: :semantic,
      handler: ->(_user) { {available: true, tool: 'missing_rest'} }
    )

    begin
      result = registry.apply_capabilities(:issue_search, modes, User.find(2))

      assert_equal({available: false}, result[:semantic])
    ensure
      if previous
        capabilities[key] = previous
      else
        capabilities.delete(key)
      end
    end
  end
end
