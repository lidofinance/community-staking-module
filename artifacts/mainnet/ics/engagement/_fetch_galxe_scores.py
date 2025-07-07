import requests

if __name__ == '__main__':
    api_url = "https://graphigo.prd.galaxy.eco/query"
    lido_space_id = 22849
    query = """
        query($spaceId: Int, $cursor: String) {
      space(id:$spaceId) {
        id
        name
        loyaltyPointsRanks(first:100,cursorAfter:$cursor)
        {
          pageInfo{
            hasNextPage
            endCursor
          }
          edges {
            node {
              points
              address {
                username
                address
              }
            }
          }
        }
      }
    }
    """

    def fetch_all_items():
        cursor = None
        all_items = []
        while True:
            variables = {"spaceId": lido_space_id, "cursor": cursor}
            response = requests.post(
                api_url,
                json={"query": query, "variables": variables},
                headers={"Content-Type": "application/json"}
            )
            response.raise_for_status()
            data = response.json()['data']['space']['loyaltyPointsRanks']

            for edge in data['edges']:
                all_items.append(edge['node'])

            page_info = data['pageInfo']
            if not page_info['hasNextPage']:
                break
            cursor = page_info['endCursor']
            print(f"Fetched {len(all_items)} items from Galxe API.")
        return all_items

    all_items = fetch_all_items()
    with open("galxe_scores.json", "w") as f:
        import json
        json.dump(all_items, f, indent=2)
