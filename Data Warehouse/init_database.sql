/*
===============================================================================
Data Warehouse Initialization Script
===============================================================================
Purpose:
    This script recreates the DataWarehouse database and sets up the
    bronze, silver, and gold schemas for organizing ETL data layers.
===============================================================================
*/

USE master;
GO

-- Drop and recreate the 'DataWarehouse' database
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'DataWarehouse')
BEGIN
    ALTER DATABASE DataWarehouse SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE DataWarehouse;
END;
GO

-- Create the 'DataWarehouse' database
CREATE DATABASE DataWarehouse;
GO

USE DataWarehouse;
GO

-- Create bronze Schema
CREATE SCHEMA bronze;
GO

-- Create silver Schema
CREATE SCHEMA silver;
GO

-- Create gold Schema
CREATE SCHEMA gold;
GO