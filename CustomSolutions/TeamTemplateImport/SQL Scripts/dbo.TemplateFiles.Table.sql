/****** Object:  Table [dbo].[TemplateFiles]    Script Date: 3/7/2021 11:10:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TemplateFiles](
	[templateid] [bigint] NOT NULL,
	[filename] [nvarchar](200) NOT NULL,
 CONSTRAINT [PK_TemplateFiles] PRIMARY KEY CLUSTERED 
(
	[templateid] ASC,
	[filename] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
