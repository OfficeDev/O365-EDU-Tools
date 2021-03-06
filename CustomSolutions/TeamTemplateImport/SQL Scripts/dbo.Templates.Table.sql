/****** Object:  Table [dbo].[Templates]    Script Date: 3/7/2021 11:10:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Templates](
	[templateid] [bigint] IDENTITY(1,1) NOT NULL,
	[template] [nvarchar](200) NOT NULL,
	[sourceteamid] [nvarchar](50) NULL,
 CONSTRAINT [PK_Templates] PRIMARY KEY CLUSTERED 
(
	[templateid] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
