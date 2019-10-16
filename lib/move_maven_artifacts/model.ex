defmodule MoveMavenArtifacts.Model do

  defmodule Artifact do
    defstruct [group: nil, name: nil, version: nil, kind: nil, link: nil]
  end

  defmodule ArtifactGroup do
    defstruct [group: nil, name: nil, version: nil, pom_file: nil, file: nil, packaging: nil]
  end

end