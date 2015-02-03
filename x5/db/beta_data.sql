# removing the mark that DB is updated from script
DELETE FROM conflines WHERE name = 'DB_Update_From_Script';
# DATA

# ^^^^^^ WRITE ABOVE THIS LINE ^^^^^
# marking that DB is updated from script
INSERT INTO conflines (name, value) VALUES ('DB_Update_From_Script', 1);
