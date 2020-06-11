USE [DB]
GO

CREATE PROCEDURE [DATA_OUTPUT].[getRemote_Data]
AS
BEGIN
    EXEC [REMOTE_Server].[getRemoteData]
    IF OBJECT_ID(N'DATA_INPUT.Input_Staging') IS NOT NULL BEGIN
        DROP TABLE DATA_INPUT.Input_Staging;
    END
    SELECT *
    INTO [Target]
    FROM [REMOTE_Server].[OutputurcingBenchmark]
    IF OBJECT_ID(N'DATA_INPUT.Input') IS NOT NULL BEGIN
        DROP TABLE DATA_INPUT.Input;
    END
    SELECT *
    INTO [DATA_INPUT].Input
    from DATA_INPUT.Input_Staging
END