defmodule WebWeb.CandidateController do
  use WebWeb, :controller

  def index(conn, %{"owner_id" => owner_id, "slug" => slug, "hints" => hints}) do
    candidates =
      hints
      |> String.split(",")
      |> Twittercluster.FetchCandidates.friends_intersection()
      # |> MapSet.difference(Twittercluster.List.member_ids(owner_id, slug))
      |> Enum.to_list()

    # |> Twittercluster.FetchCandidates.attach_profile()

    json(conn, %{"candidates" => candidates})
  end
end
