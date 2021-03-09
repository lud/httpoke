defmodule Questie.HTTPoisonDispatcherTest do
  use Questie.HttpbinSuite, async: true

  setup do
    opts = [dispatcher: Questie.HTTPoisonDispatcher]
    {:ok, %{opts: opts}}
  end

  run_suite(:single)
  run_suite(:core)
  run_suite(:redirects)
  run_suite(:content_encoding)
end
