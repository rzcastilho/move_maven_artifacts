defmodule MoveMavenArtifacts do
  @moduledoc """
  Documentation for MoveMavenArtifacts.
  """

  defmodule Artifact do
    defstruct [group: nil, name: nil, version: nil, kind: nil, link: nil]
  end

  defmodule ArtifactGroup do
    defstruct [group: nil, name: nil, version: nil, pom_file: nil, file: nil, packaging: nil]
  end


  @hrefs_ignore ["../", "maven-metadata.xml", "feature/"]
  @dir_pattern ~r/\/$/
  @artifact_kind ~r/\.(?<kind>pom|jar|ear|war)$/


  def list(repo, base_path) do
    case HTTPoison.get!(repo <> base_path) do
      %HTTPoison.Response{body: body, status_code: 200} ->
        body
        |> Floki.find("a")
        |> Floki.attribute("href")
        |> Enum.filter(&(not_in(&1, @hrefs_ignore)))
        |> Enum.map(&(navigate(repo, base_path, &1)))
      _ ->
        :error
    end
  end

  def not_in(href, hrefs_ignore) do
    !(href in hrefs_ignore)
  end

  def dir_ref?(href) do
    Regex.match?(@dir_pattern, href)
  end

  def navigate(repo, base_path, href) do
    case dir_ref?(href) do
      true ->
        list(repo, base_path <> href)
      _ ->
        base_path <> href
        |> parse_artifact()
        |> match_artifact_struct(repo)
    end
  end

  def parse_artifact(artifact) do
    artifact
    |> String.split("/")
    |> Enum.reverse
    |> Enum.filter(fn item -> item != "" end)
  end

  def match_artifact_struct([file, version, name|group], repo) do
    %Artifact{
      group: group |> Enum.reverse |> Enum.join("."),
      name: name,
      version: version,
      kind: artifact_kind(file),
      link: [repo] ++ (group |> Enum.reverse) ++ [name, version, file] |> Enum.join("/")
    }
  end

  def artifact_kind(file) do
    case Regex.named_captures(@artifact_kind, file) do
      %{"kind" => kind} ->
        String.to_atom(kind)
      _ ->
        :unknown
    end
  end

  def group_artifacts(%Artifact{group: group, name: name, version: version, kind: :pom, link: file}, acc) do
    case Map.get(acc, "#{group}:#{name}:#{version}") do
      nil ->
        Map.put(acc, "#{group}:#{name}:#{version}", %ArtifactGroup{group: group, name: name, version: version, pom_file: file})
      value ->
        Map.put(acc, "#{group}:#{name}:#{version}", %ArtifactGroup{value|pom_file: file})
    end
  end

  def group_artifacts(%Artifact{group: group, name: name, version: version, kind: packaging, link: file}, acc) do
    case Map.get(acc, "#{group}:#{name}:#{version}") do
      nil ->
        Map.put(acc, "#{group}:#{name}:#{version}", %ArtifactGroup{group: group, name: name, version: version, file: file, packaging: packaging})
      value ->
        Map.put(acc, "#{group}:#{name}:#{version}", %ArtifactGroup{value|file: file, packaging: packaging})
    end
  end

  def maven_deploy(%ArtifactGroup{group: group, name: name, version: version, file: file, packaging: packaging, pom_file: pom_file}) do
    case {
      case HTTPoison.get(file) do
        {:ok, %HTTPoison.Response{body: body, status_code: 200}} ->
          File.write!("#{name}-#{version}.#{packaging}", body)
          :ok
        _ ->
          :error
      end,
      case HTTPoison.get(pom_file) do
        {:ok, %HTTPoison.Response{body: body, status_code: 200}} ->
          File.write!("#{name}-#{version}.pom", body)
          :ok
        _ ->
          :error
      end
    } do
      {:ok, :ok} ->
        IO.puts "Efetuando deploy do artefato #{name}-#{version}.#{packaging}..."
        System.cmd(
          "mvn",
          [
            "deploy:deploy-file",
            "-DgroupId=#{group}",
            "-DartifactId=#{name}",
            "-Dversion=#{version}",
            "-Dpackaging=#{packaging}",
            "-Dfile=#{name}-#{version}.#{packaging}",
            "-DpomFile=#{name}-#{version}.pom",
            "-Durl=#{@azure_url}"
          ]
        )
      _ ->
        IO.puts "Erro ao efetuar download dos arquivos #{name}-#{version}.#{packaging} e/ou #{name}-#{version}.pom"
    end

  end

  def run do
    list(@artifactory_repo, @base_path)
    |> List.flatten
    |> Enum.reduce(%{}, &group_artifacts/2)
    |> Enum.to_list()
    |> Enum.map(fn {_, value} -> maven_deploy(value) end)
  end

end
