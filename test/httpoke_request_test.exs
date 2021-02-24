defmodule HttpokeTest do
  use ExUnit.Case, async: true
  doctest Httpoke

  test "building a request" do
    # validating methods
    assert Httpoke.request(method: :post).method == :post
    assert Httpoke.request(method: :get).method == :get
    assert_raise ArgumentError, fn -> Httpoke.request(method: :UNKNOWN) end

    # adding to a path that ends with a trailing slash
    assert %URI{path: "/api/v1/a/b/c"} =
             Httpoke.request(url: "http://example.com/api/v1/")
             |> Httpoke.merge_path("a/b/c")
             |> Map.get(:url)

    # resolving a relative path
    assert %URI{path: "/api/v2/a/b/c"} =
             Httpoke.request(url: "http://example.com/api/v1")
             |> Httpoke.merge_path("v2/a/b/c")
             |> Map.get(:url)

    # replacing the path
    assert %URI{path: "/other"} =
             Httpoke.request(url: "http://example.com/api/v1")
             |> Httpoke.merge_path("/other")
             |> Map.get(:url)
  end

  test "dispatching a request" do
    assert {:error, "the method is not set"} =
             Httpoke.request(url: "http://example.com/")
             |> Httpoke.dispatch()

    dispatcher = fn _req ->
      {:ok, :the_response}
    end

    # direct dispatch with the Httpoke.Request.dispatch/2 skips validation
    assert {:ok, :the_response} =
             Httpoke.request(url: "http://example.com/")
             |> Httpoke.Request.dispatch(dispatcher)

    assert {:error, "the method is not set"} =
             Httpoke.request(url: "http://example.com/", dispatcher: dispatcher)
             |> Httpoke.dispatch()

    assert {:ok, :the_response} =
             Httpoke.request(url: "http://example.com/", method: :get, dispatcher: dispatcher)
             |> Httpoke.dispatch()

    assert {:error, "the dispatcher is not set"} =
             Httpoke.request(url: "http://example.com/", method: :get)
             |> Httpoke.dispatch()
  end

  test "basic auth helper" do
    # We call the basic_auth two times. Authrorization header can only be once
    # and must not be a list https://tools.ietf.org/html/rfc7235#appendix-C
    req =
      Httpoke.request(headers: [{"a-key", "a-value"}])
      |> Httpoke.basic_auth("username-original", "********")
      |> Httpoke.Request.merge_headers("a-key": "another-value")
      |> Httpoke.basic_auth("username-new", "********")

    expected = ["Basic #{Base.encode64("username-new:********")}"]
    assert expected == :proplists.get_all_values("authorization", req.headers)

    # Other headers are still merged
    assert "a-value, another-value" = :proplists.get_value("a-key", req.headers)
  end
end
