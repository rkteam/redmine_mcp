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

module RedmineMcp
  module Core
    module Tools
      module Boards
      module_function

        def register!
          register_list_boards
          register_list_board_topics
          register_get_board_message
        end

        def register_list_boards
          Registry.instance.register_tool(
            plugin_id: PLUGIN_ID,
            name: 'list_boards',
            title: 'List project boards',
            description: 'Return a paginated list of forum boards in one project. Each item includes id, name, description, ' \
                         'parent_id, topics_count, and messages_count. Requires project and a boards-enabled project. Use ' \
                         'before redmine_list_board_topics or redmine_get_board_message. Default limit 25, maximum 100. ' \
                         'Does not modify Redmine.',
            input_schema: {
              properties: {
                project: Helpers::PROJECT_SCHEMA
              }.merge(Helpers::PAGINATION_INPUT),
              required: ['project']
            },
            output_schema: RedmineMcp::Core::OutputSchemas::LIST_BOARDS,
            permission: ->(user, args, project) { boards_read_allowed?(user, args, project) },
            annotations: Helpers::READ_ONLY_ANNOTATIONS,
            handler: method(:list_boards)
          )
        end

        def register_list_board_topics
          Registry.instance.register_tool(
            plugin_id: PLUGIN_ID,
            name: 'list_board_topics',
            title: 'List board topics',
            description: 'Return a paginated list of root forum topics for one board_id (messages without a parent). Each ' \
                         'item includes id, subject, author, created_on, updated_on, replies_count, and board_id. Call ' \
                         'redmine_list_boards when board_id is unknown. Default limit 25, maximum 100. Does not modify ' \
                         'Redmine.',
            input_schema: {
              properties: {
                board_id: {type: 'integer', minimum: 1, description: 'Board ID from redmine_list_boards.'}
              }.merge(Helpers::PAGINATION_INPUT),
              required: ['board_id']
            },
            output_schema: RedmineMcp::Core::OutputSchemas::LIST_TOPICS,
            permission: ->(user, args, _project) { board_topics_allowed?(user, args) },
            annotations: Helpers::READ_ONLY_ANNOTATIONS,
            handler: method(:list_board_topics)
          )
        end

        def register_get_board_message
          Registry.instance.register_tool(
            plugin_id: PLUGIN_ID,
            name: 'get_board_message',
            title: 'Get board message',
            description: 'Return one forum message by message_id, including subject, content, author, board, project, and ' \
                         'a short replies list without reply bodies. Use redmine_list_board_topics when message_id is ' \
                         'unknown. Does not modify Redmine.',
            input_schema: {
              properties: {
                message_id: {type: 'integer', minimum: 1, description: 'Message ID from redmine_list_board_topics.'},
                replies_limit: {
                  type: 'integer',
                  minimum: 1,
                  maximum: Helpers::MAX_LIST_LIMIT,
                  description: 'Maximum replies to return. Default: 100'
                },
                replies_offset: {type: 'integer', minimum: 0, default: 0, description: 'Replies to skip'}
              },
              required: ['message_id']
            },
            output_schema: RedmineMcp::Core::OutputSchemas::BOARD_MESSAGE,
            permission: ->(user, args, _project) { board_message_allowed?(user, args) },
            annotations: Helpers::READ_ONLY_ANNOTATIONS,
            handler: method(:get_board_message)
          )
        end

        def list_boards(args, context)
          user = context[:user]
          project, err = find_boards_project(user, args[:project])
          return err if err

          limit = Helpers.clamp_limit(args[:limit])
          offset = Helpers.clamp_offset(args[:offset])
          boards = project.boards.order(:position, :id)
          Helpers.paginate_collection(boards, limit: limit, offset: offset) do |board|
            serialize_board(board)
          end
        end

        def list_board_topics(args, context)
          user = context[:user]
          board, err = find_visible_board(user, args[:board_id])
          return err if err

          limit = Helpers.clamp_limit(args[:limit])
          offset = Helpers.clamp_offset(args[:offset])
          topics = board.topics.includes(:author).order(:id)
          Helpers.paginate_collection(topics, limit: limit, offset: offset) do |topic|
            serialize_topic(topic)
          end
        end

        def get_board_message(args, context)
          user = context[:user]
          message = Message.visible(user).includes(:author, :board, board: :project).find_by(id: args[:message_id])
          return Helpers.error_result(:error_mcp_board_message_not_found) unless message
          return Helpers.error_result(:error_mcp_boards_not_enabled) unless message.project.module_enabled?(:boards)

          serialize_message(
            message,
            replies_limit: Helpers.nested_list_limit(args[:replies_limit]),
            replies_offset: Helpers.clamp_offset(args[:replies_offset])
          )
        end

        def find_boards_project(user, project_ref)
          project = Helpers.find_project(user, project_ref)
          return [nil, Helpers.error_result(:error_mcp_project_not_found)] unless project
          return [nil, Helpers.error_result(:error_mcp_boards_not_enabled)] unless project.module_enabled?(:boards)

          [project, nil]
        end

        def find_visible_board(user, board_id)
          board = Board.visible(user).includes(:project).find_by(id: board_id)
          return [nil, Helpers.error_result(:error_mcp_board_not_found)] unless board
          return [nil, Helpers.error_result(:error_mcp_boards_not_enabled)] unless board.project.module_enabled?(:boards)

          [board, nil]
        end

        def boards_read_allowed?(user, args, project)
          return Helpers.any_boards_project_allows?(user, :view_messages) if args[:project].blank? && project.nil?

          project ||= Helpers.find_project(user, args[:project])
          return false unless project&.module_enabled?(:boards)

          user.allowed_to?(:view_messages, project)
        end

        def board_topics_allowed?(user, args)
          return Helpers.any_boards_project_allows?(user, :view_messages) if args[:board_id].blank?

          board = Board.visible(user).find_by(id: args[:board_id])
          board&.project&.module_enabled?(:boards) && user.allowed_to?(:view_messages, board.project)
        end

        def board_message_allowed?(user, args)
          return Helpers.any_boards_project_allows?(user, :view_messages) if args[:message_id].blank?

          message = Message.visible(user).find_by(id: args[:message_id])
          message&.project&.module_enabled?(:boards) && user.allowed_to?(:view_messages, message.project)
        end

        def serialize_board(board)
          {
            id: Helpers.integer_id(board.id),
            name: board.name,
            description: board.description.to_s,
            parent_id: Helpers.integer_id(board.parent_id),
            topics_count: board.topics_count.to_i,
            messages_count: board.messages_count.to_i
          }
        end

        def serialize_topic(topic)
          {
            id: Helpers.integer_id(topic.id),
            subject: topic.subject,
            author: Helpers.serialize_user_ref(topic.author),
            created_on: topic.created_on,
            updated_on: topic.updated_on,
            replies_count: topic.replies_count.to_i,
            board_id: Helpers.integer_id(topic.board_id)
          }
        end

        def serialize_message(message, replies_limit:, replies_offset:)
          replies, replies_pagination = Helpers.paginated_nested(
            message.children.includes(:author).reorder(:created_on, :id),
            limit: replies_limit,
            offset: replies_offset
          ) do |reply|
            {
              id: Helpers.integer_id(reply.id),
              subject: reply.subject,
              author: Helpers.serialize_user_ref(reply.author),
              created_on: reply.created_on
            }
          end
          {
            id: Helpers.integer_id(message.id),
            subject: message.subject,
            content: message.content.to_s,
            author: Helpers.serialize_user_ref(message.author),
            created_on: message.created_on,
            updated_on: message.updated_on,
            board: Helpers.serialize_named_ref(message.board),
            project: Helpers.serialize_project(message.project),
            parent_id: Helpers.integer_id(message.parent_id),
            replies: replies,
            replies_pagination: replies_pagination
          }
        end
      end
    end
  end
end
