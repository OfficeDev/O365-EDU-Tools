/****** Object:  Table [dbo].[Courses]    Script Date: 3/10/2021 7:00:27 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Courses](
	[courseid] [bigint] NOT NULL,
	[course] [nvarchar](200) NOT NULL,
	[templateid] [bigint] NULL,
	[sdsteamid] [nvarchar](200) NULL,
	[completed] [bit] NULL,
 CONSTRAINT [PK_Courses] PRIMARY KEY CLUSTERED 
(
	[courseid] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[Courses]  WITH CHECK ADD  CONSTRAINT [FK_Courses_Templates] FOREIGN KEY([templateid])
REFERENCES [dbo].[Templates] ([templateid])
GO

ALTER TABLE [dbo].[Courses] CHECK CONSTRAINT [FK_Courses_Templates]
GO


