"""Validate campaign playlist structure and referenced bank entries."""

CAMPAIGN_VERSION = 1

def validate_playlist(playlist_data: dict, banks: dict[int, dict] | None = None) -> list[str]:
    """Validate campaign playlist structure and optionally check bank references."""
    errors = []
    if not isinstance(playlist_data, dict):
        return ["Playlist root must be a dictionary"]

    if playlist_data.get("campaignVersion") != CAMPAIGN_VERSION:
        errors.append(f"campaignVersion expected {CAMPAIGN_VERSION}, got {playlist_data.get('campaignVersion')}")

    if not playlist_data.get("id"):
        errors.append("Missing or empty campaign id")

    entries = playlist_data.get("playlist")
    if not isinstance(entries, list) or not entries:
        errors.append("Missing or empty playlist array")
        return errors

    seen_labels = set()
    seen_references = set()
    for idx, entry in enumerate(entries):
        if not isinstance(entry, dict):
            errors.append(f"Playlist entry {idx} is not a dictionary")
            continue
        label = entry.get("label")
        if not isinstance(label, str) or not label:
            errors.append(f"Entry {idx} missing or invalid label")
        elif label in seen_labels:
            errors.append(f"Duplicate playlist label '{label}' at entry {idx}")
        else:
            seen_labels.add(label)

        size = entry.get("size")
        if not isinstance(size, int) or size < 4 or size > 12:
            errors.append(f"Entry {idx} ({label}) invalid size {size}")

        rank = entry.get("rank")
        if not isinstance(rank, int) or rank < 1:
            errors.append(f"Entry {idx} ({label}) invalid rank {rank}")

        level_index = entry.get("index")
        if not isinstance(level_index, int) or level_index < 0:
            errors.append(f"Entry {idx} ({label}) invalid index {level_index}")
        if type(size) is int and type(rank) is int and type(level_index) is int:
            reference = (size, rank, level_index)
            if reference in seen_references:
                errors.append(f"Duplicate playlist reference {reference} at entry {idx}")
            seen_references.add(reference)

        difficulty = entry.get("difficulty")
        if not isinstance(difficulty, str) or difficulty not in ("tutorial", "easy", "medium", "hard"):
            errors.append(f"Entry {idx} ({label}) invalid difficulty '{difficulty}'")

        if banks and type(size) is int and size in banks and type(rank) is int and type(level_index) is int:
            bank = banks[size]
            ranks = bank.get("ranks", {})
            rank_str = str(rank)
            if rank_str not in ranks:
                errors.append(f"Entry {idx} ({label}): rank {rank} not found in size {size} bank")
            else:
                bank_levels = ranks[rank_str]
                if level_index < 0 or level_index >= len(bank_levels):
                    errors.append(
                        f"Entry {idx} ({label}): index {level_index} out of range for rank {rank} (has {len(bank_levels)} levels)"
                    )

    return errors


