public class SFDCObject {
        public sObject parentObject;
        public Map<String, List<sObject>> m_childRecords;
        public SFDCObject(){
            m_childRecords = new Map<String, List<sObject>> ();
        }
    }