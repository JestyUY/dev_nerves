defmodule DevNerves.UI do
  @moduledoc """
  UI utilities with fallback for when Owl is not available.
  """

  @doc """
  Check if Owl is available.
  """
  def owl_available? do
    Code.ensure_loaded?(Owl.IO)
  end

  @doc """
  Print formatted output.
  """
  def puts(data) do
    if owl_available?() do
      Owl.IO.puts(data)
    else
      # Fallback: print plain text
      IO.puts(format_plain(data))
    end
  end

  @doc """
  Select from a list of options.
  """
  def select(options, opts \\ []) do
    if owl_available?() do
      Owl.IO.select(options, opts)
    else
      # Fallback: numbered menu
      label = Keyword.get(opts, :label, "Select an option:")
      render_as = Keyword.get(opts, :render_as, & &1)

      IO.puts("\n#{label}")

      options
      |> Enum.with_index(1)
      |> Enum.each(fn {option, index} ->
        IO.puts("  #{index}. #{render_as.(option)}")
      end)

      choice = IO.gets("\nEnter number (1-#{length(options)}): ") |> String.trim()

      case Integer.parse(choice) do
        {num, _} when num >= 1 and num <= length(options) ->
          Enum.at(options, num - 1)
        _ ->
          IO.puts("Invalid choice, using first option")
          List.first(options)
      end
    end
  end

  @doc """
  Get text input.
  """
  def input(opts \\ []) do
    label = Keyword.get(opts, :label)
    secret = Keyword.get(opts, :secret, false)

    if owl_available?() do
      Owl.IO.input(opts)
    else
      # Fallback: basic input
      prompt = if label, do: "#{label}\n> ", else: "> "

      if secret do
        # Fallback: use regular input with warning (password will be visible)
        IO.puts("⚠️  Password will be visible (hidden input not available in archive mode)")
        IO.gets(prompt) |> String.trim()
      else
        IO.gets(prompt) |> String.trim()
      end
    end
  end

  @doc """
  Create a tagged/colored string.
  """
  def tag(text, color) do
    if owl_available?() do
      Owl.Data.tag(text, color)
    else
      # Fallback: plain text
      text
    end
  end

  # Convert Owl-style data to plain text
  defp format_plain(data) when is_list(data) do
    Enum.map_join(data, "", &format_plain/1)
  end

  defp format_plain(data) when is_binary(data) do
    data
  end

  defp format_plain(_data) do
    ""
  end
end
