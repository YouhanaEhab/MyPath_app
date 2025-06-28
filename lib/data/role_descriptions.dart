
const Map<String, Map<String, dynamic>> ROLE_DESCRIPTIONS = {
  "Computer Analyst": {
    "description": "Computer Systems Analysts, sometimes called systems architects, study an organization’s current computer systems and procedures, and design solutions to help the organization operate more efficiently and effectively.",
    "key_strengths": ["Analytical Skills", "Communication", "Problem-Solving", "Technical Knowledge", "Business Acumen"],
    "job_average_salary": "\$99,270 per year", // Escaped $
    "job_outlook": "10% (Much faster than average)",
    "roadmap_url": "https://www.indeed.com/career-advice/career-development/how-to-become-a-systems-analyst",
    "job_offers_url": "https://www.linkedin.com/jobs/search/?keywords=Computer%20Systems%20Analyst"
  },
  "Content/Technical Writer": {
    "description": "Content writers create written material for websites, blogs, social media, and other marketing materials. They are skilled in crafting engaging narratives that align with brand voices and SEO strategies.",
    "key_strengths": ["Excellent Writing/Editing", "Creativity", "SEO Knowledge", "Research Skills", "Adaptability"],
    "job_average_salary": "\$69,510 per year",
    "job_outlook": "4% (As fast as average)",
    "roadmap_url": "https://www.simplilearn.com/how-to-become-content-writer-article",
    "job_offers_url": "https://www.linkedin.com/jobs/search/?keywords=Content%20Writer"
  },
  "Data Analyst": {
    "description": "Data Analysts collect, clean, and interpret data sets in order to answer a question or solve a problem. They work in many industries to help organizations make better business decisions.",
    "key_strengths": ["Statistical Analysis", "SQL", "Data Visualization (e.g., Tableau, Power BI)", "Critical Thinking", "Attention to Detail"],
    "job_average_salary": "\$82,449 per year",
    "job_outlook": "23% (Much faster than average)",
    "roadmap_url": "https://www.datacamp.com/blog/data-analyst-roadmap",
    "job_offers_url": "https://www.linkedin.com/jobs/search/?keywords=Data%20Analyst"
  },
  "Data Engineer": {
    "description": "Data Engineers design and build systems for collecting, storing, and analyzing data at scale. They create data pipelines that transform raw data into useful formats for data scientists and analysts.",
    "key_strengths": ["Programming (Python, Scala)", "Big Data Technologies (e.g., Spark, Hadoop)", "Database Systems (SQL/NoSQL)", "ETL Processes", "Cloud Platforms (AWS, Azure, GCP)"],
    "job_average_salary": "\$127,114 per year",
    "job_outlook": "16% (Much faster than average)",
    "roadmap_url": "https://www.scaler.com/blog/data-engineer-roadmap/",
    "job_offers_url": "https://www.linkedin.com/jobs/search/?keywords=Data%20Engineer"
  },
  "Software Developer": {
    "description": "Software Developers are the creative minds behind computer programs. Some develop the applications that allow people to do specific tasks on a computer or another device. Others develop the underlying systems that run the devices or that control networks.",
    "key_strengths": ["Programming Languages (e.g., Python, Java, C++)", "Data Structures & Algorithms", "Problem-Solving", "Version Control (Git)", "Teamwork"],
    "job_average_salary": "\$120,730 per year",
    "job_outlook": "25% (Much faster than average)",
    "roadmap_url": "https://www.geeksforgeeks.org/software-engineering/how-to-become-a-software-developer/",
    "job_offers_url": "https://www.linkedin.com/jobs/search/?keywords=Software%20Developer"
  },
  "ML Engineer": {
    "description": "Machine Learning Engineers design and build AI systems that can learn from and make predictions based on data. They deploy machine learning models into production so they can be used in real-world applications.",
    "key_strengths": ["Machine Learning Frameworks (e.g., TensorFlow, PyTorch)", "Programming (Python)", "Data Modeling", "Mathematics (Statistics, Linear Algebra)", "Software Engineering"],
    "job_average_salary": "\$145,000 per year",
    "job_outlook": "22% (Much faster than average)",
    "roadmap_url": "https://www.geeksforgeeks.org/blogs/machine-learning-roadmap/",
    "job_offers_url": "https://www.linkedin.com/jobs/search/?keywords=ML%20Engineer"
  },
  "Management": {
    "description": "Managers plan, direct, and coordinate the administrative services of an organization. Their specific responsibilities vary, but they typically include overseeing operations, managing staff, and making strategic decisions.",
    "key_strengths": ["Leadership", "Communication", "Decision-Making", "Strategic Planning", "Financial Acumen"],
    "job_average_salary": "\$102,450 per year",
    "job_outlook": "7% (Faster than average)",
    "roadmap_url": "https://www.atlassian.com/agile/project-management/project-roadmap",
    "job_offers_url": "https://www.linkedin.com/jobs/search/?keywords=Project%20Manager"
  },
  "Marketing": {
    "description": "Marketing professionals work to generate interest in products or services. They identify target audiences, create marketing campaigns, manage brand identity, and analyze campaign results.",
    "key_strengths": ["Digital Marketing", "Creativity", "Communication", "Data Analysis", "Social Media Management"],
    "job_average_salary": "\$68,230 per year (Marketing Specialist)",
    "job_outlook": "10% (Much faster than average)",
    "roadmap_url": "https://www.upgrad.com/blog/roadmap-for-learning-digital-marketing/",
    "job_offers_url": "https://www.linkedin.com/jobs/search/?keywords=Marketing"
  },
  "Network Engineer": {
    "description": "Network Engineers, also known as network architects, design and build data communication networks, including local area networks (LANs), wide area networks (WANs), and Intranets.",
    "key_strengths": ["Networking Protocols (TCP/IP)", "Security", "Hardware Configuration (Routers, Switches)", "Problem-Solving", "Cloud Networking"],
    "job_average_salary": "\$120,520 per year",
    "job_outlook": "5% (As fast as average)",
    "roadmap_url": "https://www.pynetlabs.com/network-engineer-roadmap/",
    "job_offers_url": "https://www.linkedin.com/jobs/search/?keywords=Network%20Engineer"
  },
  "Security": {
    "description": "Information Security Analysts plan and carry out security measures to protect an organization's computer networks and systems. Their responsibilities are continually expanding as the number of cyberattacks increases.",
    "key_strengths": ["Cybersecurity Frameworks", "Risk Assessment", "Penetration Testing", "Incident Response", "Cryptography"],
    "job_average_salary": "\$102,600 per year",
    "job_outlook": "35% (Much faster than average)",
    "roadmap_url": "https://www.coursera.org/resources/job-leveling-matrix-for-cybersecurity-career-pathways",
    "job_offers_url": "https://www.linkedin.com/jobs/search/?keywords=Cybersecurity%20Analyst"
  },
  "Graphic designer": {
    "description": "Graphic designers create visual concepts, using computer software or by hand, to communicate ideas that inspire, inform, and captivate consumers. They develop the overall layout and production design for applications such as advertisements, brochures, magazines, and reports.",
    "key_strengths": ["Creativity", "Typography", "Design Software (e.g., Adobe Creative Suite)", "Communication", "Attention to Detail"],
    "job_average_salary": "\$57,990 per year",
    "job_outlook": "3% (As fast as average)",
    "roadmap_url": "https://brainstation.io/career-guides/how-to-become-a-graphic-designer",
    "job_offers_url": "https://www.linkedin.com/jobs/search/?keywords=Graphic%20Designer"
  },
  "Graphics Designer": {
    "description": "Graphic designers create visual concepts, using computer software or by hand, to communicate ideas that inspire, inform, and captivate consumers. They develop the overall layout and production design for applications such as advertisements, brochures, magazines, and reports.",
    "key_strengths": ["Creativity", "Typography", "Design Software (e.g., Adobe Creative Suite)", "Communication", "Attention to Detail"],
    "job_average_salary": "\$57,990 per year",
    "job_outlook": "3% (As fast as average)",
    "roadmap_url": "https://brainstation.io/career-guides/how-to-become-a-graphic-designer",
    "job_offers_url": "https://www.linkedin.com/jobs/search/?keywords=Graphic%20Designer"
  }
};
