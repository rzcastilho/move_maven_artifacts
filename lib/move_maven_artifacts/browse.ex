defmodule MoveMavenArtifacts.Browse do

  alias MoveMavenArtifacts.Model.Artifact

  @dir_pattern ~r/\/$/
  @artifact_kind ~r/\.(?<kind>pom|jar|ear|war)$/

  def list(repo, base_path, hrefs_ignore) do
    case HTTPoison.get!(repo <> base_path) do
      %HTTPoison.Response{body: body, status_code: 200} ->
        body
        |> Floki.find("a")
        |> Floki.attribute("href")
        |> Enum.filter(&(not_in(&1, hrefs_ignore)))
        |> Enum.map(&(navigate(repo, base_path, &1, hrefs_ignore)))
        |> List.flatten
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

  def navigate(repo, base_path, href, hrefs_ignore) do
    case dir_ref?(href) do
      true ->
        list(repo, base_path <> href, hrefs_ignore)
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

end