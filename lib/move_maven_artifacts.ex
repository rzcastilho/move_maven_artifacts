defmodule MoveMavenArtifacts do

  alias MoveMavenArtifacts.Browse
  alias MoveMavenArtifacts.Maven

  @default_hrefs_ignore ["../", "maven-metadata.xml"]

  def main(args \\ []) do
    args
    |> parse_args
    |> run
  end

  defp parse_args(args) do
    {options, _, _} = OptionParser.parse(
      args,
      switches: [help: :boolean, source: :string, target: :string, path: :string, hrefs_ignore: :string],
      aliases: [h: :help, s: :source, t: :target, p: :path, i: :hrefs_ignore]
    )
    options
  end

  defp run(:help) do
    Bunt.puts [
      :aqua,
      """
      Moves artifacts from a repo to another.
      Arguments:
        * -s/--source: Maven Repo Source
        * -t/--target: Maven Repo Target
        * -p/--path: Initial Path
        * -i/--hrefs_ignore:
      Usage: $ ./move_maven_artifacts -s <source_repo> -t <target_repo> -p <initial_path> [-i <hrefs_ignore>]
      """
    ]
  end

  defp run(source: source, target: target, path: path, hrefs_ignore: hrefs_ignore) do
    Browse.list(source, path, hrefs_ignore)
    |> Enum.reduce(%{}, &Maven.group_artifacts/2)
    |> Enum.to_list()
    |> Enum.map(fn {_, artifact} -> Maven.maven_deploy(artifact, target) end)
  end

  defp run(options) do
    case options[:help] do
      true ->
        run(:help)
      _ ->
        case {List.keymember?(options, :source, 0), List.keymember?(options, :target, 0), List.keymember?(options, :path, 0), List.keymember?(options, :hrefs_ignore, 0)}  do
          {true, true, true, false} ->
            run(source: options[:source], target: options[:target], path: options[:path], hrefs_ignore: @default_hrefs_ignore)
          {true, true, true, true} ->
            run(source: options[:source], target: options[:target], path: options[:path], hrefs_ignore: @default_hrefs_ignore ++ (options[:path] |> String.split(",")))
          _ ->
            run(:help)
        end
    end
  end

end
