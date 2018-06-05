defmodule BrodEx.Mixfile do
  @moduledoc false
  use Mix.Project

  def project do
    [app: :brod_ex,
     version: "0.1.2",
     elixir: "~> 1.4",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps(),
     dialyzer: [plt_add_deps: :transitive],
     name: "BrodEx",
     source_url: "https://github.com/moranmathias/brod_ex",
     description: "Brod wrapper for elixir",
     package: package()
    ]
  end

  def application do
    [
      extra_applications: [
        :logger,
        :brod
      ]
    ]
  end

  defp deps do
    [
      {:brod, "~> 3.0.0", runtime: false},
      {:credo, "~> 0.8", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 0.5", only: :dev, runtime: false},
      {:ex_doc, ">= 0.0.0", only: :dev}
    ]
  end

  defp package do
    [
      name: "brod_ex",
      # These are the default files included in the package
      files: ["lib", "config", "mix.exs", "README*", "LICENSE*"],
      maintainers: ["Matias Moran Losada"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/moranmathias/brod_ex"}
    ]
  end
end
