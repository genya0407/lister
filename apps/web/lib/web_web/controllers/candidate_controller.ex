defmodule WebWeb.CandidateController do
  use WebWeb, :controller

  def index(conn, %{"owner_id" => owner_id, "slug" => slug, "hints" => hints}) do
    list_member_ids =
      Twitter.Read.list_members(%{
        owner_id_or_screen_name: String.to_integer(owner_id),
        slug: slug
      })
      |> Enum.map(& &1.id)

    candidates =
      hints
      |> String.split(",")
      |> Twitter.friends_intersection()
      |> MapSet.difference(list_member_ids |> MapSet.new())
      |> Enum.to_list()
      |> Twitter.attach_profile()
      |> Enum.map(fn u -> %{id: u.id, screen_name: u.screen_name, name: u.name} end)

    json(conn, %{"candidates" => candidates})
  end
end
