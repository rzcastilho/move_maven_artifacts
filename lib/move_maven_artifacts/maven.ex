defmodule MoveMavenArtifacts.Maven do

  alias MoveMavenArtifacts.Model.Artifact
  alias MoveMavenArtifacts.Model.ArtifactGroup

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

  # TODO: Refactor this very weird function
  def maven_deploy(%ArtifactGroup{group: group, name: name, version: version, file: file, packaging: packaging, pom_file: pom_file}, target) do
    case {
      case HTTPoison.get(file) do
        {:ok, %HTTPoison.Response{body: body, status_code: 200}} ->
          File.write!("#{name}-#{version}.#{packaging}", body)
          :ok
        _ ->
          Bunt.puts [:red, "Error downloading file #{name}-#{version}.#{packaging} from source"]
          :error
      end,
      case HTTPoison.get(pom_file) do
        {:ok, %HTTPoison.Response{body: body, status_code: 200}} ->
          File.write!("#{name}-#{version}.pom", body)
          :ok
        _ ->
          Bunt.puts [:red, "Error downloading file #{name}-#{version}.pom from source"]
          :error
      end
    } do
      {:ok, :ok} ->
        Bunt.puts [:yellow, "Deploying artifact #{name}-#{version}.#{packaging}..."]
        case System.cmd(
          "mvn",
          [
            "deploy:deploy-file",
            "-DgroupId=#{group}",
            "-DartifactId=#{name}",
            "-Dversion=#{version}",
            "-Dpackaging=#{packaging}",
            "-Dfile=#{name}-#{version}.#{packaging}",
            "-DpomFile=#{name}-#{version}.pom",
            "-Durl=#{target}"
          ]
        ) do
          {_, 0} ->
            Bunt.puts [:green, "Artifact #{name}-#{version}.#{packaging} successful deployed!"]
            :ok
          {error, _} ->
            Bunt.puts [:red, "Error deplpoying artifact #{name}-#{version}.#{packaging}. Details:"]
            Bunt.puts [:orangered, error]
            :error
        end
      _ ->
        :error
    end
    File.rm("#{name}-#{version}.#{packaging}")
    File.rm("#{name}-#{version}.pom")
  end

end