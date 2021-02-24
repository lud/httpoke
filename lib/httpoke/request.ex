defmodule Httpoke.Request do
  alias __MODULE__

  @enforce_keys [:__no_litteral__]
  defstruct headers: [],
            url: nil,
            method: nil,
            assigns: %{},
            dispatcher: nil

  @methods ~w(get post put patch delete options head)a
  @options ~w(method url dispatcher headers)a

  defguard is_method(method) when method in @methods
  defguard is_url(url) when is_binary(url) or is_struct(url, URI)

  defguard is_dispatcher(dispatcher)
           when (is_atom(dispatcher) and nil != dispatcher) or
                  is_function(dispatcher, 1)

  def new(opts \\ []) do
    Enum.reduce(opts, Request.__struct__(), &init_check_opt/2)
  end

  ##
  ## 
  ##

  defp init_check_opt({key, value}, %Request{} = req) when key in @options do
    init_opt({key, value}, req)
  end

  defp init_check_opt({key, value}, _) do
    raise ArgumentError, message: "unknown option #{inspect(key)} with value: #{inspect(value)}"
  end

  defp init_check_opt(other, _) do
    raise ArgumentError, message: "invalid option: #{inspect(other)}"
  end

  defp init_opt({:method, method}, req) when is_method(method) do
    put_method(req, method)
  end

  defp init_opt({:url, url}, req) when is_url(url) do
    put_url(req, url)
  end

  defp init_opt({:dispatcher, dispatcher}, req) when is_dispatcher(dispatcher) do
    put_dispatcher(req, dispatcher)
  end

  defp init_opt({:headers, headers}, req) when is_list(headers) do
    merge_headers(req, headers)
  end

  defp init_opt({opt, v}, _) do
    raise ArgumentError, message: "invalid value for option #{opt}: #{inspect(v)}"
  end

  ##
  ## 
  ##

  defp put_url(%Request{} = req, url) when is_url(url) do
    %Request{req | url: URI.parse(url)}
  end

  defp put_method(%Request{} = req, method) when is_method(method) do
    %Request{req | method: method}
  end

  defp put_dispatcher(%Request{} = req, dispatcher) when is_dispatcher(dispatcher) do
    %Request{req | dispatcher: dispatcher}
  end

  def merge_path(%Request{url: nil}, path) when is_binary(path) do
    raise ArgumentError, message: "cannot merge path as base url is not set"
  end

  def merge_path(%Request{url: %URI{} = url} = req, path) when is_url(path) do
    %Request{req | url: URI.merge(url, path)}
  end

  @single_value_headers ~w(authorization)

  def merge_headers(%Request{headers: current_headers} = req, headers) when is_list(headers) do
    headers =
      headers
      |> Enum.map(&cast_header/1)
      |> Enum.reduce(current_headers, fn
        {:replace, k, v}, acc ->
          List.keystore(acc, k, 0, {k, v})

        {:merge, k, v}, acc ->
          case List.keyfind(acc, k, 0) do
            {^k, old} -> List.keystore(acc, k, 0, {k, "#{old}, #{v}"})
            nil -> [{k, v} | acc]
          end
      end)

    %Request{req | headers: headers}
  end

  defp cast_header({k, v}) do
    v = to_string(v)
    # if the header must be single-value we will replace it. Otherwise we will
    # merge the values
    case cast_header_key(k) do
      k when k in @single_value_headers -> {:replace, k, v}
      k -> {:merge, k, v}
    end
  end

  defp cast_header(header) do
    raise ArgumentError, message: "invalid header, expected a 2-tuple, got: #{inspect(header)}"
  end

  defp cast_header_key(k) do
    case k do
      k when is_binary(k) -> k
      k when is_atom(k) -> Atom.to_string(k)
      other -> raise ArgumentError, message: "invalid header name #{inspect(other)}"
    end
    |> String.downcase()
  end

  def basic_auth(%Request{} = req, username, password)
      when is_binary(username) and is_binary(password) do
    auth = "Basic " <> Base.encode64("#{username}:#{password}")
    merge_headers(req, [{"authorization", auth}])
  end

  ##
  ## 
  ##

  def dispatch(%Request{} = req) do
    case validate(req) do
      {:ok, _req} -> dispatch(req, req.dispatcher)
      {:error, _} = err -> err
    end
  end

  @doc false
  def dispatch(%Request{} = req, dispatcher) when is_atom(dispatcher) do
    dispatcher.dispatch(req)
  end

  def dispatch(%Request{} = req, dispatcher) when is_function(dispatcher, 1) do
    dispatcher.(req)
  end

  @validators [:url, :method, :dispatcher]

  def validate(req) do
    Enum.reduce(@validators, {:ok, req}, &validate_loop/2)
  end

  defp validate_loop(validator, {:ok, req}) do
    validate(validator, req)
  end

  defp validate_loop(_validator, {:error, _} = err) do
    err
  end

  defp validate(:url, %Request{url: url} = req) do
    case url do
      %URI{} -> {:ok, req}
      nil -> {:error, "the url is not set"}
      invalid -> {:error, "invalid url #{inspect(invalid)}"}
    end
  end

  defp validate(:method, %Request{method: method} = req) do
    case method do
      m when m in @methods -> {:ok, req}
      nil -> {:error, "the method is not set"}
      invalid -> {:error, "invalid method #{inspect(invalid)}"}
    end
  end

  defp validate(:dispatcher, %Request{dispatcher: dispatcher} = req) do
    case dispatcher do
      d when is_dispatcher(d) -> {:ok, req}
      nil -> {:error, "the dispatcher is not set"}
      invalid -> {:error, "invalid dispatcher #{inspect(invalid)}"}
    end
  end

  defp validate(other, %Request{} = _req) do
    raise ArgumentError, message: "unknown request validator #{inspect(other)}"
  end
end
