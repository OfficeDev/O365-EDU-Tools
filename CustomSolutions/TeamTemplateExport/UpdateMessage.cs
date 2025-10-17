using System;

namespace DistributeTemplates
{
    public class UpdateMessage
    {
        public string Event { get; set; }
        public Guid JobId { get; set; }
        public DateTime? Time { get; set; }
        public string SiteId { get; set; }
        public string WebId { get; set; }
        public string DbId { get; set; }
        public string FarmId { get; set; }
        public string ServerId { get; set; }
        public string CorrelationId { get; set; }
        public string ErrorCode { get; set; }
        public string ErrorType { get; set; }
        public string Message { get; set; }
        public int? FilesCreated { get; set; }
        public int? BytesProcessed { get; set; }
        public string ObjectsProcessed { get; set; }
        public int? TotalErrors { get; set; }
        public int? TotalWarnings { get; set; }
        public string LastSpObjectId { get; set; }
        public string TotalExpectedSpObjects { get; set; }
    }
}