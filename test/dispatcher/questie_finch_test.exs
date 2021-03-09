defmodule Questie.FinchDispatcherTest do
  use Questie.HttpbinSuite, async: true

  defmodule TestDispatcher do
    use Questie.FinchDispatcher, name: __MODULE__
  end

  setup_all do
    start_supervised({Finch, name: TestDispatcher})
    :ok
  end

  setup do
    opts = [dispatcher: TestDispatcher]
    {:ok, %{opts: opts}}
  end

  test "basic" do
    Questie.request(
      method: :get,
      url: Questie.HttpbinSuite.remote() <> "get",
      dispatcher: TestDispatcher
    )
    |> Questie.dispatch()
  end

  run_suite(:single)
  run_suite(:core)
  run_suite(:redirects)
  run_suite(:content_encoding)
end
