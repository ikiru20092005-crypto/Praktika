-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Хост: 127.0.0.1
-- Время создания: Май 05 2026 г., 21:29
-- Версия сервера: 10.4.32-MariaDB
-- Версия PHP: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- База данных: `corestorecrm`
--

DELIMITER $$
--
-- Процедуры
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_assign_employee` (IN `p_orderId` INT, IN `p_employeeId` INT)   BEGIN
    UPDATE `Order`
    SET employeeId = p_employeeId,
        orderStatusId = 2
    WHERE orderId = p_orderId;
    
    SELECT ROW_COUNT() AS rowsUpdated;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_close_appeal` (IN `p_appealId` INT, IN `p_employeeId` INT)   BEGIN
    DECLARE v_statusId INT;
    
    -- Проверяем, существует ли статус "Закрыто" (ID = 4)
    SELECT appealStatusId INTO v_statusId 
    FROM AppealStatus 
    WHERE appealStatusId = 4;
    
    IF v_statusId IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Ошибка: статус "Закрыто" (ID=4) не найден в таблице AppealStatus';
    ELSE
        UPDATE Appeal
        SET closeDate = CURDATE(),
            changeDate = CURDATE(),
            appealStatusId = 4,
            employeeId = p_employeeId
        WHERE appealId = p_appealId;
        
        SELECT ROW_COUNT() AS rowsUpdated;
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_create_order` (IN `p_address` VARCHAR(500), IN `p_userId` INT, IN `p_currencyId` INT, IN `p_productId` INT)   BEGIN
    DECLARE v_price DECIMAL(10,2);
    DECLARE v_unitId INT;
    
    -- Получаем цену и единицу измерения товара
    SELECT p.priceId, pr.amount, p.unitId 
    INTO @v_priceId, v_price, v_unitId
    FROM Product p
    JOIN Price pr ON p.priceId = pr.priceId
    WHERE p.productId = p_productId;
    
    -- Создаём заказ
    INSERT INTO `Order` (startDate, address, amount, userId, unitId, orderStatusId, currencyId)
    VALUES (CURDATE(), p_address, v_price, p_userId, v_unitId, 1, p_currencyId);
    
    -- Получаем ID созданного заказа
    SET @v_orderId = LAST_INSERT_ID();
    
    -- Добавляем содержимое заказа
    INSERT INTO OrderContent (orderId, productId)
    VALUES (@v_orderId, p_productId);
    
    -- Возвращаем ID созданного заказа
    SELECT @v_orderId AS newOrderId;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Структура таблицы `appeal`
--

CREATE TABLE `appeal` (
  `appealId` int(11) NOT NULL,
  `closeDate` date DEFAULT NULL,
  `changeDate` date DEFAULT NULL,
  `description` text NOT NULL,
  `appealStatusId` int(11) NOT NULL,
  `userId` int(11) NOT NULL,
  `employeeId` int(11) DEFAULT NULL,
  `appealTypeId` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Дамп данных таблицы `appeal`
--

INSERT INTO `appeal` (`appealId`, `closeDate`, `changeDate`, `description`, `appealStatusId`, `userId`, `employeeId`, `appealTypeId`) VALUES
(7, NULL, NULL, 'Как узнать статус моего заказа №882?', 1, 5, NULL, 2),
(8, NULL, '2024-03-16', 'Ноутбук не включается после покупки', 2, 5, 1, 1),
(9, '2024-03-15', '2024-03-15', 'Спасибо за быструю доставку!', 3, 5, 1, 5);

--
-- Триггеры `appeal`
--
DELIMITER $$
CREATE TRIGGER `trg_appeal_update_timestamp` BEFORE UPDATE ON `appeal` FOR EACH ROW BEGIN
    SET NEW.changeDate = CURDATE();
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Структура таблицы `appealstatus`
--

CREATE TABLE `appealstatus` (
  `appealStatusId` int(11) NOT NULL,
  `name` varchar(100) NOT NULL,
  `description` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Дамп данных таблицы `appealstatus`
--

INSERT INTO `appealstatus` (`appealStatusId`, `name`, `description`) VALUES
(1, 'Новое', 'Обращение только что создано'),
(2, 'В работе', 'Обращение назначено менеджеру'),
(3, 'Закрыто', 'Обращение обработано, ответ отправлен'),
(4, 'Закрыто', 'Обращение закрыто');

-- --------------------------------------------------------

--
-- Структура таблицы `appealtype`
--

CREATE TABLE `appealtype` (
  `appealTypeId` int(11) NOT NULL,
  `name` varchar(100) NOT NULL,
  `description` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Дамп данных таблицы `appealtype`
--

INSERT INTO `appealtype` (`appealTypeId`, `name`, `description`) VALUES
(1, 'Гарантийное обслуживание', 'Вопросы по гарантии и ремонту'),
(2, 'Статус заказа', 'Уточнение статуса и сроков доставки'),
(3, 'Наличие товара', 'Вопросы о наличии товаров на складе'),
(4, 'Консультация', 'Подбор и консультация по товарам'),
(5, 'Прочее', 'Другие вопросы');

-- --------------------------------------------------------

--
-- Структура таблицы `currency`
--

CREATE TABLE `currency` (
  `currencyId` int(11) NOT NULL,
  `name` varchar(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Дамп данных таблицы `currency`
--

INSERT INTO `currency` (`currencyId`, `name`) VALUES
(1, 'RUB'),
(2, 'USD'),
(3, 'EUR');

-- --------------------------------------------------------

--
-- Структура таблицы `department`
--

CREATE TABLE `department` (
  `departmentId` int(11) NOT NULL,
  `name` varchar(100) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Дамп данных таблицы `department`
--

INSERT INTO `department` (`departmentId`, `name`) VALUES
(1, 'Отдел продаж'),
(2, 'Склад'),
(3, 'Бухгалтерия');

-- --------------------------------------------------------

--
-- Структура таблицы `employee`
--

CREATE TABLE `employee` (
  `employeeId` int(11) NOT NULL,
  `fullName` varchar(255) NOT NULL,
  `contacts` varchar(500) DEFAULT NULL,
  `positionId` int(11) DEFAULT NULL,
  `departmentId` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Дамп данных таблицы `employee`
--

INSERT INTO `employee` (`employeeId`, `fullName`, `contacts`, `positionId`, `departmentId`) VALUES
(1, 'Игнатьев Алексей Петрович', 'ignatiev@kora.ru, +79001234567', 1, 1),
(2, 'Смирнова Елена Викторовна', 'smirnova@kora.ru, +79007654321', 2, 1),
(3, 'Петров Дмитрий Сергеевич', 'petrov@kora.ru, +79005554433', 3, 2);

-- --------------------------------------------------------

--
-- Структура таблицы `order`
--

CREATE TABLE `order` (
  `orderId` int(11) NOT NULL,
  `startDate` date NOT NULL DEFAULT curdate(),
  `endDate` date DEFAULT NULL,
  `address` varchar(500) NOT NULL,
  `amount` decimal(10,2) NOT NULL,
  `userId` int(11) NOT NULL,
  `unitId` int(11) NOT NULL,
  `orderStatusId` int(11) NOT NULL,
  `employeeId` int(11) DEFAULT NULL,
  `currencyId` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Дамп данных таблицы `order`
--

INSERT INTO `order` (`orderId`, `startDate`, `endDate`, `address`, `amount`, `userId`, `unitId`, `orderStatusId`, `employeeId`, `currencyId`) VALUES
(14, '2024-03-15', NULL, 'г. Москва, ул. Ленина, д. 10, кв. 5', 75000.00, 5, 1, 1, 1, 1),
(15, '2024-03-16', NULL, 'г. Москва, пр. Мира, д. 25, кв. 12', 3500.00, 5, 1, 2, 1, 1),
(16, '2024-03-10', '2024-03-14', 'г. Москва, ул. Гагарина, д. 7', 78500.00, 5, 1, 3, 1, 1),
(17, '2026-05-05', NULL, '', 75000.00, 5, 1, 1, NULL, 1);

--
-- Триггеры `order`
--
DELIMITER $$
CREATE TRIGGER `trg_order_status_history` AFTER UPDATE ON `order` FOR EACH ROW BEGIN
    IF OLD.orderStatusId <> NEW.orderStatusId THEN
        INSERT INTO OrderStatusHistory (orderId, oldStatusId, newStatusId, changedBy)
        VALUES (OLD.orderId, OLD.orderStatusId, NEW.orderStatusId, CURRENT_USER());
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Структура таблицы `ordercontent`
--

CREATE TABLE `ordercontent` (
  `orderContentId` int(11) NOT NULL,
  `orderId` int(11) NOT NULL,
  `productId` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Дамп данных таблицы `ordercontent`
--

INSERT INTO `ordercontent` (`orderContentId`, `orderId`, `productId`) VALUES
(10, 14, 1),
(11, 14, 2),
(12, 15, 1),
(13, 16, 2),
(14, 17, 1);

-- --------------------------------------------------------

--
-- Структура таблицы `orderstatus`
--

CREATE TABLE `orderstatus` (
  `orderStatusId` int(11) NOT NULL,
  `name` varchar(100) NOT NULL,
  `description` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Дамп данных таблицы `orderstatus`
--

INSERT INTO `orderstatus` (`orderStatusId`, `name`, `description`) VALUES
(1, 'В обработке', 'Заказ принят, ожидает обработки'),
(2, 'В пути', 'Заказ передан в доставку'),
(3, 'Доставлен', 'Заказ доставлен клиенту'),
(4, 'Отменен', 'Заказ отменен');

-- --------------------------------------------------------

--
-- Структура таблицы `orderstatushistory`
--

CREATE TABLE `orderstatushistory` (
  `historyId` int(11) NOT NULL,
  `orderId` int(11) NOT NULL,
  `oldStatusId` int(11) DEFAULT NULL,
  `newStatusId` int(11) DEFAULT NULL,
  `changeDate` timestamp NOT NULL DEFAULT current_timestamp(),
  `changedBy` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Дамп данных таблицы `orderstatushistory`
--

INSERT INTO `orderstatushistory` (`historyId`, `orderId`, `oldStatusId`, `newStatusId`, `changeDate`, `changedBy`) VALUES
(1, 1, 1, 2, '2026-05-03 13:00:33', 'root@localhost'),
(2, 1, 2, 3, '2026-05-03 13:00:54', 'root@localhost');

-- --------------------------------------------------------

--
-- Структура таблицы `position`
--

CREATE TABLE `position` (
  `positionId` int(11) NOT NULL,
  `name` varchar(100) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Дамп данных таблицы `position`
--

INSERT INTO `position` (`positionId`, `name`) VALUES
(1, 'Менеджер по продажам'),
(2, 'Руководитель отдела продаж'),
(3, 'Кладовщик');

-- --------------------------------------------------------

--
-- Структура таблицы `price`
--

CREATE TABLE `price` (
  `priceId` int(11) NOT NULL,
  `startDate` date NOT NULL,
  `endDate` date DEFAULT NULL,
  `amount` decimal(10,2) NOT NULL,
  `currencyId` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Дамп данных таблицы `price`
--

INSERT INTO `price` (`priceId`, `startDate`, `endDate`, `amount`, `currencyId`) VALUES
(1, '2024-01-01', '2024-12-31', 75000.00, 1),
(2, '2024-01-01', NULL, 3500.00, 1),
(3, '2024-03-01', NULL, 1200.00, 1);

-- --------------------------------------------------------

--
-- Структура таблицы `product`
--

CREATE TABLE `product` (
  `productId` int(11) NOT NULL,
  `name` varchar(255) NOT NULL,
  `description` text DEFAULT NULL,
  `honestSign` int(11) DEFAULT NULL,
  `unitId` int(11) NOT NULL,
  `productTypeId` int(11) NOT NULL,
  `priceId` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Дамп данных таблицы `product`
--

INSERT INTO `product` (`productId`, `name`, `description`, `honestSign`, `unitId`, `productTypeId`, `priceId`) VALUES
(1, 'Ноутбук ASUS VivoBook', '15.6\", Intel Core i5, 8GB RAM, 512GB SSD', 1, 1, 1, 1),
(2, 'Мышь Logitech MX Master 3', 'Беспроводная, эргономичная', 1, 1, 2, 2),
(3, 'Сумка для ноутбука 15\"', 'Чёрная, водонепроницаемая', 0, 1, 3, 3);

-- --------------------------------------------------------

--
-- Структура таблицы `producttype`
--

CREATE TABLE `producttype` (
  `productTypeId` int(11) NOT NULL,
  `name` varchar(255) NOT NULL,
  `description` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Дамп данных таблицы `producttype`
--

INSERT INTO `producttype` (`productTypeId`, `name`, `description`) VALUES
(1, 'Ноутбук', 'Портативные компьютеры'),
(2, 'Периферия', 'Клавиатуры, мыши, мониторы'),
(3, 'Аксессуар', 'Сумки, зарядные устройства');

-- --------------------------------------------------------

--
-- Структура таблицы `role`
--

CREATE TABLE `role` (
  `roleId` int(11) NOT NULL,
  `name` varchar(100) NOT NULL,
  `description` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Дамп данных таблицы `role`
--

INSERT INTO `role` (`roleId`, `name`, `description`) VALUES
(1, 'Клиент', 'Зарегистрированный пользователь магазина'),
(2, 'Менеджер', 'Сотрудник отдела продаж'),
(3, 'Руководитель', 'Руководитель отдела продаж'),
(4, 'Администратор', 'Администратор системы');

-- --------------------------------------------------------

--
-- Структура таблицы `unit`
--

CREATE TABLE `unit` (
  `unitId` int(11) NOT NULL,
  `name` varchar(100) NOT NULL,
  `description` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Дамп данных таблицы `unit`
--

INSERT INTO `unit` (`unitId`, `name`, `description`) VALUES
(1, 'шт', 'Штука'),
(2, 'компл', 'Комплект'),
(3, 'упак', 'Упаковка');

-- --------------------------------------------------------

--
-- Структура таблицы `user`
--

CREATE TABLE `user` (
  `userId` int(11) NOT NULL,
  `email` varchar(255) NOT NULL,
  `password` varchar(255) NOT NULL,
  `password_salt` varchar(32) NOT NULL DEFAULT '',
  `password_hash` varchar(64) NOT NULL DEFAULT '',
  `name` varchar(255) NOT NULL,
  `phone` varchar(20) DEFAULT NULL,
  `roleId` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Дамп данных таблицы `user`
--

INSERT INTO `user` (`userId`, `email`, `password`, `password_salt`, `password_hash`, `name`, `phone`, `roleId`) VALUES
(5, 'ikiru20092005@mail.ru', '', 'f0a366a6e68e56367dfaea043327aa24', '9f7ee4259c33dcf068e154e9838b1a27fa884719a9a79476e945958993530a12', 'Виталий', '+79855531624', 4),
(6, 'client1@mail.ru', '123123', '', '', 'Огеенко Виталий Владимирович', '+79161234567', 1),
(7, 'client2@mail.ru', '123123', '', '', 'Иванов Иван Иванович', '+79169876543', 1),
(8, 'manager1@kora.ru', '123123', '', '', 'Игнатьев Алексей Петрович', '+79001234567', 2),
(9, 'director@kora.ru', '123123', '', '', 'Смирнова Елена Викторовна', '+79007654321', 3);

-- --------------------------------------------------------

--
-- Дублирующая структура для представления `v_appeal_statistics`
-- (См. Ниже фактическое представление)
--
CREATE TABLE `v_appeal_statistics` (
`appealTypeName` varchar(100)
,`appealTypeDescription` text
,`appealStatusName` varchar(100)
,`totalAppeals` bigint(21)
,`avgProcessingDays` decimal(10,4)
);

-- --------------------------------------------------------

--
-- Дублирующая структура для представления `v_order_details`
-- (См. Ниже фактическое представление)
--
CREATE TABLE `v_order_details` (
`orderId` int(11)
,`startDate` date
,`endDate` date
,`address` varchar(500)
,`amount` decimal(10,2)
,`clientName` varchar(255)
,`clientEmail` varchar(255)
,`clientPhone` varchar(20)
,`statusName` varchar(100)
,`statusDescription` text
,`employeeName` varchar(255)
,`employeeContacts` varchar(500)
,`currencyName` varchar(50)
);

-- --------------------------------------------------------

--
-- Структура таблицы `waitinglist`
--

CREATE TABLE `waitinglist` (
  `waitingListId` int(11) NOT NULL,
  `productId` int(11) NOT NULL,
  `userId` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Дамп данных таблицы `waitinglist`
--

INSERT INTO `waitinglist` (`waitingListId`, `productId`, `userId`) VALUES
(2, 1, 5);

-- --------------------------------------------------------

--
-- Структура для представления `v_appeal_statistics`
--
DROP TABLE IF EXISTS `v_appeal_statistics`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `v_appeal_statistics`  AS SELECT `at`.`name` AS `appealTypeName`, `at`.`description` AS `appealTypeDescription`, `ast`.`name` AS `appealStatusName`, count(`a`.`appealId`) AS `totalAppeals`, avg(to_days(`a`.`closeDate`) - to_days(`a`.`changeDate`)) AS `avgProcessingDays` FROM ((`appeal` `a` join `appealtype` `at` on(`a`.`appealTypeId` = `at`.`appealTypeId`)) join `appealstatus` `ast` on(`a`.`appealStatusId` = `ast`.`appealStatusId`)) GROUP BY `at`.`appealTypeId`, `at`.`name`, `at`.`description`, `ast`.`appealStatusId`, `ast`.`name` ;

-- --------------------------------------------------------

--
-- Структура для представления `v_order_details`
--
DROP TABLE IF EXISTS `v_order_details`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `v_order_details`  AS SELECT `o`.`orderId` AS `orderId`, `o`.`startDate` AS `startDate`, `o`.`endDate` AS `endDate`, `o`.`address` AS `address`, `o`.`amount` AS `amount`, `u`.`name` AS `clientName`, `u`.`email` AS `clientEmail`, `u`.`phone` AS `clientPhone`, `os`.`name` AS `statusName`, `os`.`description` AS `statusDescription`, `e`.`fullName` AS `employeeName`, `e`.`contacts` AS `employeeContacts`, `c`.`name` AS `currencyName` FROM ((((`order` `o` join `user` `u` on(`o`.`userId` = `u`.`userId`)) join `orderstatus` `os` on(`o`.`orderStatusId` = `os`.`orderStatusId`)) left join `employee` `e` on(`o`.`employeeId` = `e`.`employeeId`)) join `currency` `c` on(`o`.`currencyId` = `c`.`currencyId`)) ;

--
-- Индексы сохранённых таблиц
--

--
-- Индексы таблицы `appeal`
--
ALTER TABLE `appeal`
  ADD PRIMARY KEY (`appealId`),
  ADD KEY `appealStatusId` (`appealStatusId`),
  ADD KEY `userId` (`userId`),
  ADD KEY `employeeId` (`employeeId`),
  ADD KEY `appealTypeId` (`appealTypeId`);

--
-- Индексы таблицы `appealstatus`
--
ALTER TABLE `appealstatus`
  ADD PRIMARY KEY (`appealStatusId`);

--
-- Индексы таблицы `appealtype`
--
ALTER TABLE `appealtype`
  ADD PRIMARY KEY (`appealTypeId`);

--
-- Индексы таблицы `currency`
--
ALTER TABLE `currency`
  ADD PRIMARY KEY (`currencyId`);

--
-- Индексы таблицы `department`
--
ALTER TABLE `department`
  ADD PRIMARY KEY (`departmentId`);

--
-- Индексы таблицы `employee`
--
ALTER TABLE `employee`
  ADD PRIMARY KEY (`employeeId`),
  ADD KEY `positionId` (`positionId`),
  ADD KEY `departmentId` (`departmentId`);

--
-- Индексы таблицы `order`
--
ALTER TABLE `order`
  ADD PRIMARY KEY (`orderId`),
  ADD KEY `userId` (`userId`),
  ADD KEY `unitId` (`unitId`),
  ADD KEY `orderStatusId` (`orderStatusId`),
  ADD KEY `employeeId` (`employeeId`),
  ADD KEY `currencyId` (`currencyId`);

--
-- Индексы таблицы `ordercontent`
--
ALTER TABLE `ordercontent`
  ADD PRIMARY KEY (`orderContentId`),
  ADD KEY `orderId` (`orderId`),
  ADD KEY `productId` (`productId`);

--
-- Индексы таблицы `orderstatus`
--
ALTER TABLE `orderstatus`
  ADD PRIMARY KEY (`orderStatusId`);

--
-- Индексы таблицы `orderstatushistory`
--
ALTER TABLE `orderstatushistory`
  ADD PRIMARY KEY (`historyId`);

--
-- Индексы таблицы `position`
--
ALTER TABLE `position`
  ADD PRIMARY KEY (`positionId`);

--
-- Индексы таблицы `price`
--
ALTER TABLE `price`
  ADD PRIMARY KEY (`priceId`),
  ADD KEY `currencyId` (`currencyId`);

--
-- Индексы таблицы `product`
--
ALTER TABLE `product`
  ADD PRIMARY KEY (`productId`),
  ADD KEY `unitId` (`unitId`),
  ADD KEY `productTypeId` (`productTypeId`),
  ADD KEY `priceId` (`priceId`);

--
-- Индексы таблицы `producttype`
--
ALTER TABLE `producttype`
  ADD PRIMARY KEY (`productTypeId`);

--
-- Индексы таблицы `role`
--
ALTER TABLE `role`
  ADD PRIMARY KEY (`roleId`);

--
-- Индексы таблицы `unit`
--
ALTER TABLE `unit`
  ADD PRIMARY KEY (`unitId`);

--
-- Индексы таблицы `user`
--
ALTER TABLE `user`
  ADD PRIMARY KEY (`userId`),
  ADD UNIQUE KEY `email` (`email`),
  ADD KEY `roleId` (`roleId`);

--
-- Индексы таблицы `waitinglist`
--
ALTER TABLE `waitinglist`
  ADD PRIMARY KEY (`waitingListId`),
  ADD UNIQUE KEY `userId` (`userId`),
  ADD KEY `productId` (`productId`);

--
-- AUTO_INCREMENT для сохранённых таблиц
--

--
-- AUTO_INCREMENT для таблицы `appeal`
--
ALTER TABLE `appeal`
  MODIFY `appealId` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=10;

--
-- AUTO_INCREMENT для таблицы `appealstatus`
--
ALTER TABLE `appealstatus`
  MODIFY `appealStatusId` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT для таблицы `appealtype`
--
ALTER TABLE `appealtype`
  MODIFY `appealTypeId` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT для таблицы `currency`
--
ALTER TABLE `currency`
  MODIFY `currencyId` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT для таблицы `department`
--
ALTER TABLE `department`
  MODIFY `departmentId` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT для таблицы `employee`
--
ALTER TABLE `employee`
  MODIFY `employeeId` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT для таблицы `order`
--
ALTER TABLE `order`
  MODIFY `orderId` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=18;

--
-- AUTO_INCREMENT для таблицы `ordercontent`
--
ALTER TABLE `ordercontent`
  MODIFY `orderContentId` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=15;

--
-- AUTO_INCREMENT для таблицы `orderstatus`
--
ALTER TABLE `orderstatus`
  MODIFY `orderStatusId` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT для таблицы `orderstatushistory`
--
ALTER TABLE `orderstatushistory`
  MODIFY `historyId` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT для таблицы `position`
--
ALTER TABLE `position`
  MODIFY `positionId` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT для таблицы `price`
--
ALTER TABLE `price`
  MODIFY `priceId` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT для таблицы `product`
--
ALTER TABLE `product`
  MODIFY `productId` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT для таблицы `producttype`
--
ALTER TABLE `producttype`
  MODIFY `productTypeId` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT для таблицы `role`
--
ALTER TABLE `role`
  MODIFY `roleId` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT для таблицы `unit`
--
ALTER TABLE `unit`
  MODIFY `unitId` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT для таблицы `user`
--
ALTER TABLE `user`
  MODIFY `userId` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=10;

--
-- AUTO_INCREMENT для таблицы `waitinglist`
--
ALTER TABLE `waitinglist`
  MODIFY `waitingListId` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- Ограничения внешнего ключа сохраненных таблиц
--

--
-- Ограничения внешнего ключа таблицы `appeal`
--
ALTER TABLE `appeal`
  ADD CONSTRAINT `appeal_ibfk_1` FOREIGN KEY (`appealStatusId`) REFERENCES `appealstatus` (`appealStatusId`),
  ADD CONSTRAINT `appeal_ibfk_2` FOREIGN KEY (`userId`) REFERENCES `user` (`userId`),
  ADD CONSTRAINT `appeal_ibfk_3` FOREIGN KEY (`employeeId`) REFERENCES `employee` (`employeeId`),
  ADD CONSTRAINT `appeal_ibfk_4` FOREIGN KEY (`appealTypeId`) REFERENCES `appealtype` (`appealTypeId`);

--
-- Ограничения внешнего ключа таблицы `employee`
--
ALTER TABLE `employee`
  ADD CONSTRAINT `employee_ibfk_1` FOREIGN KEY (`positionId`) REFERENCES `position` (`positionId`),
  ADD CONSTRAINT `employee_ibfk_2` FOREIGN KEY (`departmentId`) REFERENCES `department` (`departmentId`);

--
-- Ограничения внешнего ключа таблицы `order`
--
ALTER TABLE `order`
  ADD CONSTRAINT `order_ibfk_1` FOREIGN KEY (`userId`) REFERENCES `user` (`userId`),
  ADD CONSTRAINT `order_ibfk_2` FOREIGN KEY (`unitId`) REFERENCES `unit` (`unitId`),
  ADD CONSTRAINT `order_ibfk_3` FOREIGN KEY (`orderStatusId`) REFERENCES `orderstatus` (`orderStatusId`),
  ADD CONSTRAINT `order_ibfk_4` FOREIGN KEY (`employeeId`) REFERENCES `employee` (`employeeId`),
  ADD CONSTRAINT `order_ibfk_5` FOREIGN KEY (`currencyId`) REFERENCES `currency` (`currencyId`);

--
-- Ограничения внешнего ключа таблицы `ordercontent`
--
ALTER TABLE `ordercontent`
  ADD CONSTRAINT `ordercontent_ibfk_1` FOREIGN KEY (`orderId`) REFERENCES `order` (`orderId`) ON DELETE CASCADE,
  ADD CONSTRAINT `ordercontent_ibfk_2` FOREIGN KEY (`productId`) REFERENCES `product` (`productId`);

--
-- Ограничения внешнего ключа таблицы `price`
--
ALTER TABLE `price`
  ADD CONSTRAINT `price_ibfk_1` FOREIGN KEY (`currencyId`) REFERENCES `currency` (`currencyId`);

--
-- Ограничения внешнего ключа таблицы `product`
--
ALTER TABLE `product`
  ADD CONSTRAINT `product_ibfk_1` FOREIGN KEY (`unitId`) REFERENCES `unit` (`unitId`),
  ADD CONSTRAINT `product_ibfk_2` FOREIGN KEY (`productTypeId`) REFERENCES `producttype` (`productTypeId`),
  ADD CONSTRAINT `product_ibfk_3` FOREIGN KEY (`priceId`) REFERENCES `price` (`priceId`);

--
-- Ограничения внешнего ключа таблицы `user`
--
ALTER TABLE `user`
  ADD CONSTRAINT `user_ibfk_1` FOREIGN KEY (`roleId`) REFERENCES `role` (`roleId`);

--
-- Ограничения внешнего ключа таблицы `waitinglist`
--
ALTER TABLE `waitinglist`
  ADD CONSTRAINT `waitinglist_ibfk_1` FOREIGN KEY (`productId`) REFERENCES `product` (`productId`),
  ADD CONSTRAINT `waitinglist_ibfk_2` FOREIGN KEY (`userId`) REFERENCES `user` (`userId`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
