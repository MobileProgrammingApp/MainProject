-- Homepal - temiz veritabani semasi (veri icermez, sadece tablo yapisi)
-- Kaynak: dbs15146355.sql dokumundan turetildi, INSERT'ler kaldirildi.

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET time_zone = "+00:00";

CREATE TABLE `home_members` (
  `id` int NOT NULL,
  `house_id` int NOT NULL,
  `name` varchar(100) COLLATE utf8mb4_general_ci NOT NULL,
  `role` varchar(50) COLLATE utf8mb4_general_ci DEFAULT 'member',
  `fcm_token` text COLLATE utf8mb4_general_ci
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE `house_chores` (
  `id` int NOT NULL,
  `creator_id` int NOT NULL,
  `assigned_to_id` int NOT NULL,
  `task_name` varchar(255) COLLATE utf8mb4_general_ci NOT NULL,
  `is_done` tinyint(1) DEFAULT '0',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE `house_infos` (
  `id` int NOT NULL,
  `house_id` int NOT NULL,
  `title` varchar(100) COLLATE utf8mb4_general_ci NOT NULL,
  `value` varchar(255) COLLATE utf8mb4_general_ci NOT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE `house_inventory` (
  `id` int NOT NULL,
  `house_id` int NOT NULL,
  `item_name` varchar(100) COLLATE utf8mb4_general_ci NOT NULL,
  `location` varchar(255) COLLATE utf8mb4_general_ci NOT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE `polls` (
  `id` int NOT NULL,
  `house_id` int NOT NULL,
  `question` varchar(255) COLLATE utf8mb4_general_ci NOT NULL,
  `is_active` tinyint(1) DEFAULT '1',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE `poll_options` (
  `id` int NOT NULL,
  `poll_id` int NOT NULL,
  `option_text` varchar(100) COLLATE utf8mb4_general_ci NOT NULL,
  `vote_count` int DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE `poll_votes` (
  `id` int NOT NULL,
  `poll_id` int NOT NULL,
  `house_id` int NOT NULL,
  `member_id` int NOT NULL,
  `option_id` int NOT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE `shopping_list` (
  `id` int NOT NULL,
  `item_name` varchar(255) COLLATE utf8mb4_general_ci NOT NULL,
  `user_id` int DEFAULT NULL,
  `is_bought` tinyint(1) DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE `users` (
  `id` int NOT NULL,
  `house_name` varchar(100) COLLATE utf8mb4_general_ci NOT NULL,
  `email` varchar(255) COLLATE utf8mb4_general_ci NOT NULL,
  `password` varchar(255) COLLATE utf8mb4_general_ci NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

ALTER TABLE `home_members`
  ADD PRIMARY KEY (`id`),
  ADD KEY `house_id` (`house_id`);

ALTER TABLE `house_chores`
  ADD PRIMARY KEY (`id`),
  ADD KEY `creator_id` (`creator_id`),
  ADD KEY `assigned_to_id` (`assigned_to_id`);

ALTER TABLE `house_infos`
  ADD PRIMARY KEY (`id`),
  ADD KEY `house_id` (`house_id`);

ALTER TABLE `house_inventory`
  ADD PRIMARY KEY (`id`),
  ADD KEY `house_id` (`house_id`);

ALTER TABLE `polls`
  ADD PRIMARY KEY (`id`),
  ADD KEY `house_id` (`house_id`);

ALTER TABLE `poll_options`
  ADD PRIMARY KEY (`id`),
  ADD KEY `poll_id` (`poll_id`);

ALTER TABLE `poll_votes`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `unique_member_vote` (`poll_id`,`member_id`),
  ADD KEY `house_id` (`house_id`),
  ADD KEY `member_id` (`member_id`);

ALTER TABLE `shopping_list`
  ADD PRIMARY KEY (`id`),
  ADD KEY `user_id` (`user_id`);

ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `email` (`email`);

ALTER TABLE `home_members` MODIFY `id` int NOT NULL AUTO_INCREMENT;
ALTER TABLE `house_chores` MODIFY `id` int NOT NULL AUTO_INCREMENT;
ALTER TABLE `house_infos` MODIFY `id` int NOT NULL AUTO_INCREMENT;
ALTER TABLE `house_inventory` MODIFY `id` int NOT NULL AUTO_INCREMENT;
ALTER TABLE `polls` MODIFY `id` int NOT NULL AUTO_INCREMENT;
ALTER TABLE `poll_options` MODIFY `id` int NOT NULL AUTO_INCREMENT;
ALTER TABLE `poll_votes` MODIFY `id` int NOT NULL AUTO_INCREMENT;
ALTER TABLE `shopping_list` MODIFY `id` int NOT NULL AUTO_INCREMENT;
ALTER TABLE `users` MODIFY `id` int NOT NULL AUTO_INCREMENT;

ALTER TABLE `home_members`
  ADD CONSTRAINT `home_members_ibfk_1` FOREIGN KEY (`house_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

ALTER TABLE `house_chores`
  ADD CONSTRAINT `house_chores_ibfk_1` FOREIGN KEY (`creator_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `house_chores_ibfk_2` FOREIGN KEY (`assigned_to_id`) REFERENCES `home_members` (`id`) ON DELETE CASCADE;

ALTER TABLE `house_infos`
  ADD CONSTRAINT `house_infos_ibfk_1` FOREIGN KEY (`house_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

ALTER TABLE `house_inventory`
  ADD CONSTRAINT `house_inventory_ibfk_1` FOREIGN KEY (`house_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

ALTER TABLE `polls`
  ADD CONSTRAINT `polls_ibfk_1` FOREIGN KEY (`house_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

ALTER TABLE `poll_options`
  ADD CONSTRAINT `poll_options_ibfk_1` FOREIGN KEY (`poll_id`) REFERENCES `polls` (`id`) ON DELETE CASCADE;

ALTER TABLE `poll_votes`
  ADD CONSTRAINT `poll_votes_ibfk_1` FOREIGN KEY (`poll_id`) REFERENCES `polls` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `poll_votes_ibfk_2` FOREIGN KEY (`house_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `poll_votes_ibfk_3` FOREIGN KEY (`member_id`) REFERENCES `home_members` (`id`) ON DELETE CASCADE;

ALTER TABLE `shopping_list`
  ADD CONSTRAINT `shopping_list_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;
