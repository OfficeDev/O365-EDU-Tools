/****** Object:  Table [dbo].[TemplateChannels]    Script Date: 3/7/2021 11:10:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TemplateChannels](
	[templateid] [bigint] NOT NULL,
	[channel] [nvarchar](200) NOT NULL,
 CONSTRAINT [PK_TemplateChannels] PRIMARY KEY CLUSTERED 
(
	[templateid] ASC,
	[channel] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[TemplateChannels]  WITH CHECK ADD  CONSTRAINT [FK_TemplateChannels_Templates] FOREIGN KEY([templateid])
REFERENCES [dbo].[Templates] ([templateid])
GO
ALTER TABLE [dbo].[TemplateChannels] CHECK CONSTRAINT [FK_TemplateChannels_Templates]
GO
