CREATE TABLE IF NOT EXISTS `player_xp` (
    `citizenid` VARCHAR(50) NOT NULL,
    `level` INT(11) NOT NULL DEFAULT 1,
    `current_xp` INT(11) NOT NULL DEFAULT 0,
    `total_xp` INT(11) NOT NULL DEFAULT 0,
    PRIMARY KEY (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;