using System;
using System.Collections.Generic;

namespace DistributeTemplates
{
    public class SourceFile
    {
        public SourceFile()
        {
            Properties = new Dictionary<string, string>();
        }

        public string Filename { get; set; }

        public DateTime LastModified { get; set; }

        public byte[] Contents { get; set; }

        public string Title { get; set; }

        public Dictionary<string,string> Properties { get; set; }
    }
}