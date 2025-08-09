return {
  strategy = "chat",
  description = "Commit staged changes",
  opts = {
    is_slash_cmd = true,
    short_name = "gcommit",
    auto_submit = true,
    adapter = {
      name = "copilot",
      model = "gpt-4.1",
    },
  },
  prompts = {
    {
      role = "user",
      content = function()
        return string.format([[You are an expert at following the Conventional Commit specification. Given the git diff listed below, please generate a commit message for me:

```diff
%s
```

Using @{cmd_runner}, git commit the changes. Important: First, write down the commit message and then proceed to call the tool without asking for my prompt. Use git commit -m, do not stage any changes!
]], vim.fn.system("git diff --no-ext-diff --staged"))
      end,
      opts = {
        contains_code = true,
      },
    },
  },
}
