local utils = require 'codecompanion.utils.adapters'

return require('codecompanion.adapters').extend('openai_compatible', {
  name = 'perplexity',
  formatted_name = 'Perplexity',
  roles = {
    llm = 'assistant',
    user = 'user',
  },
  env = {
    api_key = 'cmd:op read "op://Employee/Perplexity API key/password" --no-newline',
    url = 'https://api.perplexity.ai',
    chat_url = '/chat/completions',
  },
  handlers = {
    ---Output the data from the API ready for insertion into the chat buffer
    ---@param self CodeCompanion.Adapter
    ---@param data table The streamed JSON data from the API, also formatted by the format_data handler
    ---@param tools? table The table to write any tool output to
    ---@return table|nil [status: string, output: table]
    chat_output = function(self, data, tools)
      if not data or data == '' then
        return nil
      end

      -- Handle both streamed data and structured response
      local data_mod = type(data) == 'table' and data.body or utils.clean_streamed_data(data)
      local ok, json = pcall(vim.json.decode, data_mod, { luanil = { object = true } })

      if not ok or not json.choices or #json.choices == 0 then
        return nil
      end

      -- Process tool calls from all choices
      if self.opts.tools and tools then
        for _, choice in ipairs(json.choices) do
          local delta = self.opts.stream and choice.delta or choice.message

          if delta and delta.tool_calls and #delta.tool_calls > 0 then
            for i, tool in ipairs(delta.tool_calls) do
              local tool_index = tool.index and tonumber(tool.index) or i

              -- Some endpoints like Gemini do not set this (why?!)
              local id = tool.id
              if not id or id == '' then
                id = string.format('call_%s_%s', json.created, i)
              end

              if self.opts.stream then
                local found = false
                for _, existing_tool in ipairs(tools) do
                  if existing_tool._index == tool_index then
                    -- Append to arguments if this is a continuation of a stream
                    if tool['function'] and tool['function']['arguments'] then
                      existing_tool['function']['arguments'] = (existing_tool['function']['arguments'] or '') .. tool['function']['arguments']
                    end
                    found = true
                    break
                  end
                end

                if not found then
                  table.insert(tools, {
                    _index = tool_index,
                    id = id,
                    type = tool.type,
                    ['function'] = {
                      name = tool['function']['name'],
                      arguments = tool['function']['arguments'] or '',
                    },
                  })
                end
              else
                table.insert(tools, {
                  _index = i,
                  id = id,
                  type = tool.type,
                  ['function'] = {
                    name = tool['function']['name'],
                    arguments = tool['function']['arguments'],
                  },
                })
              end
            end
          end
        end
      end

      -- Process message content from the first choice
      local choice = json.choices[1]
      local delta = self.opts.stream and choice.delta or choice.message

      if not delta then
        return nil
      end

      local output = {
        status = 'success',
        output = {
          role = delta.role,
          content = delta.content,
        },
      }

      if choice.finish_reason then
        local resultString = ''
        if json.citations then
          for i, result in ipairs(json.search_results) do
            resultString = resultString .. '[' .. tostring(i) .. ']: ' .. '[' .. result.title .. ']' .. '(' .. result.url .. ')' .. '\n'
          end
          output.output.content = output.output.content .. '\n\n' .. resultString
        end
      end

      return output
    end,
  },
  schema = {
    model = {
      order = 1,
      mapping = 'parameters',
      type = 'enum',
      desc = 'The name of the model that will complete your prompt.',
      default = 'sonar',
      choices = {
        ['sonar-deep-research'] = { opts = { can_reason = true } },
        ['sonar-reasoning'] = { opts = { can_reason = true } },
        ['sonar-reasoning-pro'] = { opts = { can_reason = true } },
        'sonar',
        'sonar-pro',
        'r1-1776',
      },
    },
    search_mode = {
      order = 2,
      mapping = 'parameters',
      type = 'string',
      optional = true,
      desc = 'Controls the search mode used for the request.',
      default = 'web',
      choices = {
        'academic',
        'web',
      },
    },
    reasoning_effort = {
      order = 3,
      mapping = 'parameters',
      type = 'string',
      optional = true,
      condition = function(self)
        local model = self.schema.model.default
        if type(model) == 'function' then
          model = model()
        end
        if self.schema.model.choices[model] and self.schema.model.choices[model].opts then
          return self.schema.model.choices[model].opts.can_reason
        end
        return false
      end,
      desc = 'Controls how much computational effort the AI dedicates to each query for deep research models. WARNING: This parameter is ONLY applicable for sonar-deep-research.',
      default = 'medium',
      choices = {
        'high',
        'medium',
        'low',
      },
    },
    temperature = {
      order = 4,
      mapping = 'parameters',
      type = 'number',
      optional = true,
      desc = 'The amount of randomness in the response, valued between 0 and 2. Lower values (e.g., 0.1) make the output more focused, deterministic, and less creative. Higher values (e.g., 1.5) make the output more random and creative.',
      default = 0.2,
      validate = function(n)
        return n >= 0 and n <= 2, 'Must be between 0 and 2'
      end,
    },
    top_p = {
      order = 5,
      mapping = 'parameters',
      type = 'number',
      optional = true,
      desc = 'The nucleus sampling threshold, valued between 0 and 1. Controls the diversity of generated text by considering only the tokens whose cumulative probability exceeds the top_p value. Lower values (e.g., 0.5) make the output more focused and deterministic, while higher values (e.g., 0.95) allow for more diverse outputs.',
      default = 0.9,
      validate = function(n)
        return n >= 0 and n <= 1, 'Must be between 0 and 1'
      end,
    },
    max_tokens = {
      order = 6,
      mapping = 'parameters',
      type = 'integer',
      optional = true,
      desc = 'The maximum number of tokens to generate in the completion.',
      default = nil,
      validate = function(n)
        return n > 0, 'Must be greater than 0'
      end,
    },
    search_domain_filter = {
      order = 7,
      mapping = 'parameters',
      type = 'list',
      optional = true,
      description = 'A list of domains to limit search results to. Currently limited to 10 domains for Allowlisting and Denylisting. For Denylisting, add a - at the beginning of the domain string.',
      default = nil,
      subtype = {
        type = 'string',
      },
      validate = function(l)
        return #l <= 10, 'Must be 10 or fewer domains'
      end,
    },
  },
})
