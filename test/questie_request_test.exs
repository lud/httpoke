defmodule QuestieTest do
  use ExUnit.Case, async: true
  doctest Questie

  test "building a request" do
    # validating methods
    assert Questie.request(method: :post).method == :post
    assert Questie.request(method: :get).method == :get
    assert_raise ArgumentError, fn -> Questie.request(method: :UNKNOWN) end

    # adding to a path that ends with a trailing slash
    assert %URI{path: "/api/v1/a/b/c"} =
             Questie.request(url: "http://example.com/api/v1/")
             |> Questie.merge_path("a/b/c")
             |> Map.get(:url)

    # resolving a relative path
    assert %URI{path: "/api/v2/a/b/c"} =
             Questie.request(url: "http://example.com/api/v1")
             |> Questie.merge_path("v2/a/b/c")
             |> Map.get(:url)

    # replacing the path
    assert %URI{path: "/other"} =
             Questie.request(url: "http://example.com/api/v1")
             |> Questie.merge_path("/other")
             |> Map.get(:url)
  end

  test "dispatching a request" do
    assert {:error, "the method is not set"} =
             Questie.request(url: "http://example.com/")
             |> Questie.dispatch()

    dispatcher = fn _req ->
      {:ok, :the_response}
    end

    # direct dispatch with the Questie.Request.do_dispatch/2 skips validation
    assert {:ok, :the_response} =
             Questie.request(url: "http://example.com/")
             |> Questie.Request.do_dispatch(dispatcher)

    assert {:error, "the method is not set"} =
             Questie.request(url: "http://example.com/", dispatcher: dispatcher)
             |> Questie.dispatch()

    assert {:ok, :the_response} =
             Questie.request(
               url: "http://example.com/",
               method: :get,
               dispatcher: dispatcher
             )
             |> Questie.dispatch()

    assert {:error, "the dispatcher is not set"} =
             Questie.request(url: "http://example.com/", method: :get)
             |> Questie.dispatch()
  end

  test "basic auth helper" do
    # We call the basic_auth two times. Authrorization header can only be once
    # and must not be a list https://tools.ietf.org/html/rfc7235#appendix-C
    # We expect the value from the last call to be set, and only this one.
    req =
      Questie.request(headers: [{"a-key", "a-value"}])
      |> Questie.basic_auth("username-original", "********")
      |> Questie.Request.merge_headers("a-key": "another-value")
      |> Questie.basic_auth("username-new", "********")

    expected = ["Basic #{Base.encode64("username-new:********")}"]
    assert expected == :proplists.get_all_values("authorization", req.headers)

    # Other headers are still merged
    assert "a-value, another-value" = :proplists.get_value("a-key", req.headers)
  end

  test "setting a body with an encoding function" do
    dispatcher = fn req ->
      assert Jason.decode!(req.body) == %{"hello" => "world"}
      {:ok, nil}
    end

    assert {:ok, _} =
             Questie.request(dispatcher: dispatcher, url: "/", method: :post)
             |> Questie.encode_with(&Jason.encode/1)
             |> Questie.put_body(%{hello: :world})
             |> Questie.dispatch()
             |> IO.inspect(label: "encoded")
  end
end
