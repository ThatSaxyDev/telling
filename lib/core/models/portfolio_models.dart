class PortfolioData {
  final PersonalInfo personal;
  final About about;
  final List<Service> services;
  final List<Experience> experience;
  final ProjectSection projects;
  final List<Testimonial> testimonials;
  final List<Education> education;
  final SocialLinks social;
  final Footer footer;

  PortfolioData({
    required this.personal,
    required this.about,
    required this.services,
    required this.experience,
    required this.projects,
    required this.testimonials,
    required this.education,
    required this.social,
    required this.footer,
  });

  factory PortfolioData.fromJson(Map<String, dynamic> json) {
    return PortfolioData(
      personal: PersonalInfo.fromJson(json['personal']),
      about: About.fromJson(json['about']),
      services: (json['services'] as List).map((e) => Service.fromJson(e)).toList(),
      experience: (json['experience'] as List).map((e) => Experience.fromJson(e)).toList(),
      projects: ProjectSection.fromJson(json['projects']),
      testimonials: (json['testimonials'] as List).map((e) => Testimonial.fromJson(e)).toList(),
      education: (json['education'] as List).map((e) => Education.fromJson(e)).toList(),
      social: SocialLinks.fromJson(json['social']),
      footer: Footer.fromJson(json['footer']),
    );
  }
}

class PersonalInfo {
  final String name;
  final String shortName;
  final String title;
  final List<String> roles;
  final String tagline;
  final String email;
  final String phone;
  final String location;
  final String availability;
  final String? resume;

  PersonalInfo({
    required this.name,
    required this.shortName,
    required this.title,
    required this.roles,
    required this.tagline,
    required this.email,
    required this.phone,
    required this.location,
    required this.availability,
    this.resume,
  });

  factory PersonalInfo.fromJson(Map<String, dynamic> json) {
    return PersonalInfo(
      name: json['name'],
      shortName: json['shortName'],
      title: json['title'],
      roles: List<String>.from(json['roles']),
      tagline: json['tagline'],
      email: json['email'],
      phone: json['phone'],
      location: json['location'],
      availability: json['availability'],
      resume: json['resume'],
    );
  }
}

class About {
  final List<String> bio;
  final List<String> skills;
  final List<String> interests;
  final String image;

  About({
    required this.bio,
    required this.skills,
    required this.interests,
    required this.image,
  });

  factory About.fromJson(Map<String, dynamic> json) {
    return About(
      bio: List<String>.from(json['bio']),
      skills: List<String>.from(json['skills']),
      interests: List<String>.from(json['interests']),
      image: json['image'],
    );
  }
}

class Service {
  final String id;
  final String title;
  final String description;
  final String icon;
  final List<String> technologies;

  Service({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.technologies,
  });

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      icon: json['icon'],
      technologies: List<String>.from(json['technologies']),
    );
  }
}

class Experience {
  final String company;
  final String position;
  final String location;
  final String type;
  final String startDate;
  final String? endDate;
  final bool current;
  final String description;
  final List<String> achievements;
  final List<String> technologies;

  Experience({
    required this.company,
    required this.position,
    required this.location,
    required this.type,
    required this.startDate,
    this.endDate,
    required this.current,
    required this.description,
    required this.achievements,
    required this.technologies,
  });

  factory Experience.fromJson(Map<String, dynamic> json) {
    return Experience(
      company: json['company'],
      position: json['position'],
      location: json['location'],
      type: json['type'],
      startDate: json['startDate'],
      endDate: json['endDate'],
      current: json['current'],
      description: json['description'],
      achievements: List<String>.from(json['achievements']),
      technologies: List<String>.from(json['technologies']),
    );
  }
}

class ProjectSection {
  final List<ProjectModel> featured;
  final List<ProjectModel> other;

  ProjectSection({required this.featured, required this.other});

  factory ProjectSection.fromJson(Map<String, dynamic> json) {
    return ProjectSection(
      featured: (json['featured'] as List).map((e) => ProjectModel.fromJson(e)).toList(),
      other: (json['other'] as List).map((e) => ProjectModel.fromJson(e)).toList(),
    );
  }
}

class ProjectModel {
  final String id;
  final String title;
  final String description;
  final List<String> techStack;
  final String? githubUrl;
  final String? androidUrl;
  final String? iosUrl;
  final String? webUrl;
  final String image;
  final bool featured;
  final String category;

  ProjectModel({
    required this.id,
    required this.title,
    required this.description,
    required this.techStack,
    this.githubUrl,
    this.androidUrl,
    this.iosUrl,
    this.webUrl,
    required this.image,
    required this.featured,
    required this.category,
  });

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    return ProjectModel(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      techStack: List<String>.from(json['techStack']),
      githubUrl: json['githubUrl'],
      androidUrl: json['androidUrl'],
      iosUrl: json['iosUrl'],
      webUrl: json['webUrl'],
      image: json['image'],
      featured: json['featured'],
      category: json['category'],
    );
  }
}

class Testimonial {
  final String id;
  final String name;
  final String position;
  final String company;
  final String content;
  final String image;
  final int rating;

  Testimonial({
    required this.id,
    required this.name,
    required this.position,
    required this.company,
    required this.content,
    required this.image,
    required this.rating,
  });

  factory Testimonial.fromJson(Map<String, dynamic> json) {
    return Testimonial(
      id: json['id'],
      name: json['name'],
      position: json['position'],
      company: json['company'],
      content: json['content'],
      image: json['image'],
      rating: json['rating'],
    );
  }
}

class SocialLinks {
  final String? github;
  final String? linkedin;
  final String? twitter;
  final String? instagram;
  final String? dribbble;
  final String? behance;
  final String? medium;
  final String? dev;

  SocialLinks({
    this.github,
    this.linkedin,
    this.twitter,
    this.instagram,
    this.dribbble,
    this.behance,
    this.medium,
    this.dev,
  });

  factory SocialLinks.fromJson(Map<String, dynamic> json) {
    return SocialLinks(
      github: json['github'],
      linkedin: json['linkedin'],
      twitter: json['twitter'],
      instagram: json['instagram'],
      dribbble: json['dribbble'],
      behance: json['behance'],
      medium: json['medium'],
      dev: json['dev'],
    );
  }
}

class Education {
  final String school;
  final String degree;
  final String location;
  final String date;
  final String grade;
  final List<String> majors;

  Education({
    required this.school,
    required this.degree,
    required this.location,
    required this.date,
    required this.grade,
    required this.majors,
  });

  factory Education.fromJson(Map<String, dynamic> json) {
    return Education(
      school: json['school'],
      degree: json['degree'],
      location: json['location'],
      date: json['date'],
      grade: json['grade'],
      majors: List<String>.from(json['majors']),
    );
  }
}

class Footer {
  final String copyright;
  final String builtWith;
  final String version;

  Footer({
    required this.copyright,
    required this.builtWith,
    required this.version,
  });

  factory Footer.fromJson(Map<String, dynamic> json) {
    return Footer(
      copyright: json['copyright'],
      builtWith: json['builtWith'],
      version: json['version'],
    );
  }
}
