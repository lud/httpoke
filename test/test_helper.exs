:inets.start()

remote = Questie.HttpbinSuite.remote()
test_url = String.to_charlist(remote <> "get")

case :httpc.request(:get, {test_url, []}, [], []) do
  {:ok, {{_, 200, _}, _, _}} -> :ok
  _ -> raise "cannot start unit tests: the remote #{remote} is not up"
end

ExUnit.start()
