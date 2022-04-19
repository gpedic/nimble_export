defmodule NimbleExport.MixProject do
  use Mix.Project

  @name "NimbleExport"
  @version "0.1.0"
  @url "https://github.com/gpedic/nimble_export"

  def project do
    [
      app: :nimble_export,
      version: @version,
      name: @name,
      elixir: "~> 1.5",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      description: description(),
      docs: docs(),
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:nimble_csv, "~> 1.1"},
      {:plug, "~> 1.0"},
      {:stream_data, "~> 0.5", only: :test},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:ex_doc, ">= 0.14.0", only: :dev, runtime: false},
      {:dialyxir, "~> 1.1", only: :dev, runtime: false}
    ]
  end

  defp description() do
    """
    NimbleExport - simple streamed chunk export library based on [NimbleCSV](https://github.com/dashbitco/nimble_csv)
    """
  end

  defp docs() do
    [
      main: @name,
      source_ref: "v#{@version}",
      source_url: @url,
      extras: [
        "README.md",
        "CHANGELOG.md"
      ]
    ]
  end

  defp package do
    [
      name: :nimble_export,
      files: ["lib", "mix.exs", "README*", "LICENSE*"],
      maintainers: ["Goran Pedić"],
      licenses: ["MIT"],
      links: %{"GitHub" => @url}
    ]
  end
end
