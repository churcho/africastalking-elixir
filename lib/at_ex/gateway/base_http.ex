defmodule AtEx.Gateway.Base do
  @moduledoc """
  Base HTTP Gateway for `AtEx.Gateway.Base`
  """

  @doc """
  Macro to import necessary code into HTTP Gateways, This Macro accepts a list as configuration at the moment it's used
  configure the  HTTP Base Url.

  ## Parameters
  * list: list of parameters for HTTP client configuration

  ## Examples

      defmodule AtEx.Gateway.Voice do
        use AtEx.Gateway.Base, url: "http://test.com"
        @username "some_username"

        def collect_minutes(attrs) do
          params =
          attrs
          |> Map.put(:username, @username)

          {:ok, resp} = get("/minutes", params)
          process_result(resp.body)
        end
      end
  """
  defmacro __using__(opts) do
    quote do
      use Tesla

      @config unquote(opts)

      @accept Application.get_env(:at_ex, :accept)
      @key Application.get_env(:at_ex, :api_key)
      @content_type Application.get_env(:at_ex, :content_type)

      plug(Tesla.Middleware.BaseUrl, @config[:url])

      # The `type` config is to allow the api send `application/json` check https://github.com/teamon/tesla#formats for more info. Needed in requests such as Mobile/checkput

      if @config[:type] && @config[:type] == "json" do
        plug(Tesla.Middleware.JSON)
      else
        plug(Tesla.Middleware.FormUrlencoded)
      end

      plug(Tesla.Middleware.Headers, [
        {"accept", @accept},
        {"content-type", @content_type},
        {"apikey", @key}
      ])

      @doc """
      Process results from calling the gateway
      """

      def process_result({:ok, %{status: 200} = res}) do
        if is_map(res.body) do
          {:ok, res.body}
        else
          Jason.decode(res.body)
        end
      end

      def process_result({:ok, %{status: 201} = res}) do
        if is_map(res.body) do
          {:ok, res.body}
        else
          Jason.decode(res.body)
        end
      end

      def process_result({:ok, result}) do
        {:error, %{status: result.status, message: result.body}}
      end

      def process_result({:error, result}) do
        {:error, result}
      end
    end
  end
end
