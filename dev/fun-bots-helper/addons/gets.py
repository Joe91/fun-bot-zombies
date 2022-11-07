"""This module provides all intermediary functions for the scripts in /tools.

Most functions here returns a list that will be used to write the lines of external files.
"""

import operator
import os
import sqlite3
from io import TextIOWrapper
from typing import Any, Dict, List, Tuple

import requests
from deep_translator import GoogleTranslator


def get_settings(first_key: str) -> List[Dict]:
    """Retrieve settings of SettingsDefinition.lua into a list.

    Args:
        - first_key - The key setting to be retrieved along with Description, Category and Default settings

    Returns:
        - all_settings - A list containing all settings
    """
    settings_definition = "ext/Shared/Settings/SettingsDefinition.lua"

    with open(settings_definition, "r") as in_file:
        readout_active = False
        all_settings = []
        setting = {}
        for line in in_file.read().splitlines():
            if "Elements = {" in line:
                readout_active = True
            if readout_active:
                for key in [f"{first_key} =", "Description =", "Category ="]:
                    if key in line:
                        setting[key[:-2]] = line.split('"')[-2]
                if "Default =" in line:
                    setting["Default"] = (
                        line.split("=")[-1].replace(",", "").replace(" ", "")
                    )
                if "}," in line or (len(setting) != 0 and "}" in line):
                    all_settings.append(setting)
                    setting = {}

    return all_settings


def get_settings_lines(all_settings: List[Dict]) -> List[str]:
    """Create a list of formatted setting lines to be used in Config.lua.

    Args:
        - all_settings - The list of settings

    Returns:
        - out_file_lines - A list of formatted setting lines
    """
    out_file_lines, last_category = [], None

    for setting in all_settings:
        if setting["Category"] != last_category:
            out_file_lines.append("\n	-- " + setting["Category"])
            last_category = setting["Category"]
        temp_string = "	" + setting["Name"] + " = " + setting["Default"] + ","

        width = len(temp_string)
        number_of_tabs = (41 - width) // 4
        if ((41 - width) % 4) == 0:
            number_of_tabs -= 1
        if number_of_tabs <= 0:
            number_of_tabs = 1
        out_file_lines.append(
            temp_string + "	" * number_of_tabs + "-- " + setting["Description"]
        )
    out_file_lines.append("}")

    return out_file_lines


def get_lua_lines(all_settings: List[Dict]) -> List[str]:
    """Create a list of formatted language setting lines to be used in DEFAULT.lua.

    Args:
        - all_settings - The list of settings

    Returns:
        - out_file_lines - A list of formatted language setting lines
    """
    out_file_lines = []

    last_category = None
    for setting in all_settings:
        if setting["Category"] != last_category:
            if last_category != None:
                out_file_lines.append("")
            out_file_lines.append("-- " + setting["Category"] + " ")
            last_category = setting["Category"]
        out_file_lines.append('Language:add(code, "' + setting["Text"] + '", "")')
        out_file_lines.append(
            'Language:add(code, "' + setting["Description"] + '", "")'
        )

    out_file_lines.extend(__scan_other_files())

    return out_file_lines


def __scan_other_files() -> List[str]:
    """Scan other files, besides SettingsDefinition.lua, searching for more settings.

    Args:
        None

    Returns:
        - out_file_lines_others - A list of external formatted language setting lines
    """
    list_of_translation_files = [
        "ext/Client/ClientNodeEditor.lua",
        "ext/Server/BotSpawner.lua",
        "ext/Server/UIServer.lua",
        "ext/Server/NodeCollection.lua",
    ]
    out_file_lines_others = []
    for file_name in list_of_translation_files:
        out_file_lines_others.append("\n-- Strings of " + file_name + " ")
        with open(file_name, "r") as file_with_translation:
            for line in file_with_translation.read().splitlines():
                if "Language:I18N(" in line:
                    translation = line.split("Language:I18N(")[1]
                    translation = translation.split(translation[0])[1]
                    if translation != "":
                        newLine = 'Language:add(code, "' + translation + '", "")'
                        if newLine not in out_file_lines_others:
                            out_file_lines_others.append(newLine)

    return out_file_lines_others


def get_js_lines() -> List[str]:
    """Create a list of formatted language setting lines to be used in DEFAULT.js.

    Args:
        None

    Returns:
        - out_file_lines - A list of formatted language setting lines
    """
    index_html = "WebUI/index.html"
    list_of_js_translation_files = [
        "WebUI/classes/EntryElement.js",
        "WebUI/classes/BotEditor.js",
    ]

    out_file_lines = []

    with open(index_html, "r") as in_file_html:
        for line in in_file_html.read().splitlines():
            if 'data-lang="' in line:
                translation_html = line.split('data-lang="')[1].split('"')[0]
                if translation_html not in out_file_lines:
                    out_file_lines.append(translation_html)
        for file_name in list_of_js_translation_files:
            with open(file_name, "r") as file_with_translation:
                for line in file_with_translation.read().splitlines():
                    if "I18N('" in line:
                        translation = line.split("I18N('")[1]
                        translation = translation.split("'")[0]
                        if translation not in out_file_lines:
                            out_file_lines.append(translation)

    return out_file_lines


def get_map_lines(create: bool = False, update_supported: bool = False) -> List[List]:
    """Build a list of maps to be used in MapList.txt and Supported-maps.md.

    Args:
        - create - True if we want to get the maps for MapList.txt,
        - update_supported - True if we want to update the maps of Supported-maps.md

    Returns:
        - map_items - A list of all maps' information
    """
    all_game_modes = [
        "TDM",
        "SDM",
        "TDM CQ",
        "Rush",
        "SQ Rush",
        "CQ Small",
        "CQ Large",
        "Assault",
        "Assault 2",
        "Assault Large",
        "GM",
        "CQ Dom",
        "Scavanger",
        "CTF",
        "Tank Superiority",
    ]
    game_mode_translations = {
        "TDM": "TeamDeathMatch0",
        "SDM": "SquadDeathMatch0",
        "TDM CQ": "TeamDeathMatchC0",
        "Rush": "RushLarge0",
        "SQ Rush": "SquadRush0",
        "CQ Small": "ConquestSmall0",
        "CQ Large": "ConquestLarge0",
        "Assault": "ConquestAssaultSmall0",
        "Assault 2": "ConquestAssaultSmall1",
        "Assault Large": "ConquestAssaultLarge0",
        "GM": "GunMaster0",
        "CQ Dom": "Domination0",
        "Scavanger": "Scavenger0",
        "CTF": "CaptureTheFlag0",
        "Tank Superiority": "TankSuperiority0",
    }

    if create:
        rounds_to_use = "1"
        maps_with_gunmaster = ["XP2", "XP4"]
        maps_without_tdm_cq = ["XP2"]

    if update_supported:
        maps_with_gunmaster = ["XP2", "XP4", "sp_", "coop_"]
        maps_without_tdm_cq = ["XP2", "sp_", "coop_"]

    map_items = []

    file_names = os.listdir("mapfiles")
    for file_name in file_names:
        combined_name = file_name.split(".")[0]
        name_parts = combined_name.rsplit("_", 1)
        mapname = name_parts[0]
        mapname_splitted = mapname.split("_")[0]
        translated_game_mode = name_parts[1]
        game_mode = ""

        if update_supported:
            vehicle_support = False
            with open("mapfiles" + "/" + file_name, "r") as temp_map_file:
                for line in temp_map_file.readlines():
                    if '"Vehicles":[' in line:
                        vehicle_support = True
                        break

        for mode in all_game_modes:
            if game_mode_translations[mode] == translated_game_mode:
                game_mode = mode
                break

        if game_mode in all_game_modes:
            if game_mode == "TDM":
                if create:
                    if mapname_splitted in maps_with_gunmaster:
                        map_items.append([mapname, "GunMaster0", rounds_to_use])
                    if mapname_splitted not in maps_without_tdm_cq:
                        map_items.append([mapname, translated_game_mode, rounds_to_use])
                    map_items.append([mapname, "TeamDeathMatchC0", rounds_to_use])
                if update_supported:
                    if mapname_splitted in maps_with_gunmaster:
                        map_items.append([mapname, "GM", "GunMaster0", vehicle_support])
                    if mapname_splitted not in maps_without_tdm_cq:
                        map_items.append(
                            [mapname, game_mode, translated_game_mode, vehicle_support]
                        )
                    map_items.append(
                        [mapname, "TDM CQ", "TeamDeathMatchC0", vehicle_support]
                    )
            else:
                if create:
                    map_items.append([mapname, translated_game_mode, rounds_to_use])
                if update_supported:
                    map_items.append(
                        [mapname, game_mode, translated_game_mode, vehicle_support]
                    )

    map_items = sorted(map_items, key=operator.itemgetter(2, 1))

    return map_items


def get_all_tables() -> Tuple[sqlite3.Connection, sqlite3.Cursor]:
    """Get all tables from the mod database.

    Args:
        None

    Returns:
        - connect - The object associated with the database connection
        - cursor - The object associated with the database operations
    """
    connect = sqlite3.connect("mod.db")
    cursor = connect.cursor()

    sql_instruction = """
		SELECT * FROM sqlite_master WHERE type='table'
	"""
    cursor.execute(sql_instruction)

    return connect, cursor


def get_invalid_node_lines(in_file: TextIOWrapper) -> List[str]:
    """Fix invalid nodes of all maps.

    Args:
        - in_file - The opened map file to be fixed

    Returns:
        - out_file_lines - The new lines used to update the map's node
    """
    DISTANCE_MAX = 80

    out_file_lines = in_file.readlines()
    last_path, current_path = 0, 0
    for i in range(2, len(out_file_lines) - 2):
        line = out_file_lines[i]
        current_items = line.split(";")
        current_path = int(current_items[0])
        pos_x = float(current_items[2])
        pos_y = float(current_items[3])
        pos_z = float(current_items[4])

        line = out_file_lines[i - 1]
        items = line.split(";")
        last_path = int(items[0])
        last_pos_x = float(items[2])
        last_pos_y = float(items[3])
        last_pos_z = float(items[4])

        line = out_file_lines[i + 1]
        items = line.split(";")
        next_path = int(items[0])
        next_pos_x = float(items[2])
        next_pos_y = float(items[3])
        next_pos_z = float(items[4])

        if (
            last_path == current_path and next_path == current_path
        ):  # Wrong in the middle
            if (
                abs(last_pos_x - pos_x) > DISTANCE_MAX
                or abs(last_pos_y - pos_y) > DISTANCE_MAX
                or abs(last_pos_z - pos_z) > DISTANCE_MAX
            ) and (
                abs(next_pos_x - pos_x) > DISTANCE_MAX
                or abs(next_pos_y - pos_y) > DISTANCE_MAX
                or abs(next_pos_z - pos_z) > DISTANCE_MAX
            ):
                new_pos_x = last_pos_x + (next_pos_x - last_pos_x) / 2
                new_pos_y = last_pos_y + (next_pos_y - last_pos_y) / 2
                new_pos_z = last_pos_z + (next_pos_z - last_pos_z) / 2
                current_items[2] = format(new_pos_x, ".6f")
                current_items[3] = format(new_pos_y, ".6f")
                current_items[4] = format(new_pos_z, ".6f")
                new_line_content = ";".join(current_items)
                out_file_lines[i] = new_line_content
        if last_path == current_path and next_path != current_path:  # Wrong at the end
            if (
                abs(last_pos_x - pos_x) > DISTANCE_MAX
                or abs(last_pos_y - pos_y) > DISTANCE_MAX
                or abs(last_pos_z - pos_z) > DISTANCE_MAX
            ):
                current_items[2] = format(last_pos_x + 0.2, ".6f")
                current_items[3] = format(last_pos_y, ".6f")
                current_items[4] = format(last_pos_z + 0.2, ".6f")
                new_line_content = ";".join(current_items)
                out_file_lines[i] = new_line_content
        if (
            last_path != current_path and next_path == current_path
        ):  # Wrong at the start
            if (
                abs(next_pos_x - pos_x) > DISTANCE_MAX
                or abs(next_pos_y - pos_y) > DISTANCE_MAX
                or abs(next_pos_z - pos_z) > DISTANCE_MAX
            ):
                current_items[2] = format(next_pos_x + 0.2, ".6f")
                current_items[3] = format(next_pos_y, ".6f")
                current_items[4] = format(next_pos_z + 0.2, ".6f")
                new_line_content = ";".join(current_items)
                out_file_lines[i] = new_line_content

    return out_file_lines


def get_objectives_to_rename(in_file: TextIOWrapper) -> Tuple[List[str], List[str]]:
    """Fix invalid objective names.

    Args:
        - in_file - The opened map file to have objectives fixed

    Returns:
        - out_file_lines - The new lines used to update the map's objectives
        - file_lines - A list with the original file lines
    """
    all_objectives = []
    file_lines = in_file.readlines()
    for line in file_lines[1:]:
        if '"Objectives":[' in line:
            objectives = line.split('"Objectives":[')[1].split("]")[0].split(",")
            for objective in objectives:
                if objective not in all_objectives:
                    all_objectives.append(objective)
    all_objectives.sort()
    objectives_to_rename = [
        objective_name
        for objective_name in all_objectives
        if objective_name.lower() != objective_name
    ]

    return objectives_to_rename, file_lines


def get_translation(translator: Any, line: str) -> str:
    """Translate a line from one language to another.

    Args:
        - translator - The translator object used to translate it
        - line - The line to be translated

    Returns:
        - str - The translated line
    """
    splitted_line = line.split('"')
    splitted_line.remove("")
    splitted_line.insert(3, translator.translate(splitted_line[1]))
    return '"'.join(splitted_line)


def get_updated_lines_lua(in_file: TextIOWrapper) -> List[str]:
    """Update all lua language files based on DEFAULT.lua.

    Args:
        - in_file - The file to be updated

    Returns:
        - out_file_lines - A list with all translated lines, including new ones
    """
    language_file = "ext/Shared/Languages/DEFAULT.lua"
    with open(language_file, "r", encoding="utf8") as lua_file:
        lua_lines = lua_file.read().splitlines()

    out_file_lines = in_file.read().splitlines()

    LANG = out_file_lines[0].split("'")[1].split("_")[0]
    if LANG == "cn":
        LANG = "zh-CN"

    translator = GoogleTranslator(source="en", target=LANG)

    lines_to_remove = [
        out_line for out_line in out_file_lines if "Language:add" in out_line
    ]
    lines_to_add = []

    for line in lua_lines:
        if "Language:add" in line:
            line_found = False
            line_part = line.split('",')[0]
            for out_line in out_file_lines:
                if "Language:add" in out_line:
                    line_part_2 = out_line.split('",')[0]
                    if line_part == line_part_2:
                        line_found = True
                        if out_line in lines_to_remove:
                            lines_to_remove.remove(out_line)
                        break
            if line_found == False:
                lines_to_add.append(get_translation(translator, line))
    for remove_line in lines_to_remove:
        out_file_lines.remove(remove_line)
    for add_line in lines_to_add:
        out_file_lines.append(add_line)
    return out_file_lines


def get_updated_lines_js(in_file: TextIOWrapper) -> List[str]:
    """Update all JS language files based on DEFAULT.js.

    Args:
        - in_file - The file to be updated

    Returns:
        - out_file_lines - A list with all translated lines, including new ones
    """
    language_file_js = "WebUI/languages/DEFAULT.js"

    with open(language_file_js, "r", encoding="utf8") as js_file:
        js_lines = js_file.read().splitlines()

    out_file_lines = in_file.read().splitlines()

    LANG = out_file_lines[0].split("'")[1].split("_")[0]
    if LANG == "cn":
        LANG = "zh-CN"
    translator = GoogleTranslator(source="en", target=LANG)

    lines_to_remove = [out_line for out_line in out_file_lines[6:] if ":" in out_line]
    lines_to_add = []

    for line in js_lines[6:]:
        if ":" in line:
            line_found = False
            line_part = line.split('": ')[0].replace(" ", "").replace("	", "")
            for out_line in out_file_lines[6:]:
                if ":" in line:
                    line_part_2 = (
                        out_line.split('": ')[0].replace(" ", "").replace("	", "")
                    )
                    if line_part == line_part_2:
                        line_found = True
                        if out_line in lines_to_remove:
                            lines_to_remove.remove(out_line)
                        break
            if line_found == False:
                if line.startswith('\t"') and not line.split(":")[0].startswith('\t""'):
                    lines_to_add.append(get_translation(translator, line))
    for remove_line in lines_to_remove:
        out_file_lines.remove(remove_line)
    for add_line in lines_to_add:
        out_file_lines.insert(-1, add_line)

    return out_file_lines


def get_to_root() -> None:
    """Go back to the fun-bots root, i.e, /fun-bots.

    Args:
        None

    Returns:
        None
    """
    cwd_splitted = os.getcwd().replace("\\", "/").split("/")
    last_index_pos = len(cwd_splitted) - cwd_splitted[::-1].index("fun-bots") - 1
    new_cwd = "/".join(
        cwd_splitted[: cwd_splitted.index("fun-bots", last_index_pos) + 1]
    )
    os.chdir(new_cwd)


def get_recursive_correction(
    replacements: List, line: str, c_factor: int, i: int = 0
) -> str:
    """Recursively correct the grammar of comments.

    Args:
        - replacements - A list with grammar changes
        - line - The line to be changed
        - c_factor - A factor to correct offsets during the recursion process
        - i - A flag to control the grammar issue we're fixing

    Returns:
        - line - The line grammarly updated
    """
    if i != len(replacements):
        value = replacements[i]["value"]
        offset = replacements[i]["offset"] + c_factor
        length = replacements[i]["length"]

        new_line = line[:offset] + value + line[offset + length :]
        c_factor += len(value) - length
        i += 1
        return get_recursive_correction(replacements, new_line, c_factor, i)
    else:
        return get_punctuation(line)


def get_punctuation(line: str) -> str:
    """Punctuate and break line.

    Args:
        - line - The line to be formatted

    Returns:
        - line - A formatted line
    """
    if line[-2] != ".":
        if line[-2] in ["!", "?", "=", ")", "["]:
            return line[:-1] + " \n"
        else:
            return line[:-1] + ". \n"
    return line[:-1] + " \n"


def get_variable_existence(line: str) -> bool:
    """Check if a line has camelCase variables.

    Args:
        - line - The line to be checked

    Returns:
        - bool - True if it has variables, False otherwise
    """
    for char_index, char in enumerate(line[:-1]):
        if char.islower() and line[char_index + 1].isupper():
            return True
    return False


def get_comments_fixed(in_file: TextIOWrapper) -> List[str]:
    """Create a list with grammarly updated comments.

    Args:
        - in_file - The file to be updated

    Returns:
        - out_file_lines - A list with comments updated
    """
    out_file_lines = []
    lines = in_file.readlines()
    for line in lines:
        try:
            if (
                line[-2] != " "
                and "--" in line
                and "---" not in line
                and "-->" not in line
            ):
                index = line.index("--") + 2

                if line[index:][0] != " ":
                    if line[index : index + 2] == "[[":
                        index += 2
                        line = line[:index] + " " + line[index:]
                    else:
                        line = line[:index] + " " + line[index:]

                words_ignore = ["raycast", "raycasts", "raycasting", "botlist"]

                data = {"text": line[index:], "language": "en-GB"}
                check_grammar = requests.post(
                    "https://api.languagetool.org/v2/check", data=data
                ).json()

                try:
                    replacements = []
                    for message in check_grammar["matches"]:
                        part_line = line[
                            index
                            + message["offset"] : index
                            + message["offset"]
                            + message["length"]
                        ]
                        if (
                            part_line.lower() not in words_ignore
                            and not get_variable_existence(part_line)
                        ):

                            replacements.append(
                                {
                                    "value": message["replacements"][0]["value"],
                                    "offset": message["offset"],
                                    "length": message["length"],
                                }
                            )
                except IndexError:
                    out_file_lines.append(get_punctuation(line))
                    continue

                out_file_lines.append(
                    get_recursive_correction(replacements, line, index)
                )
            else:
                out_file_lines.append(line)
        except IndexError:
            out_file_lines.append(line)

    return out_file_lines
