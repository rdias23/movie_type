class PersonalityArchetypeService
  ARCHETYPES = {
    "AGEA" => {
      title: "The Visionary Explorer",
      description: "You are drawn to films that push the boundaries of imagination and artistry. Like a cosmic traveler through the cinematic universe, you seek out stories that challenge conventional narratives and embrace experimental storytelling. Your appreciation for both grand artistic visions and emotional authenticity makes you a true connoisseur of transformative cinema."
    },
    "AGEI" => {
      title: "The Philosophical Dreamer",
      description: "Cinema is your gateway to deeper understanding. You gravitate towards films that weave complex narratives with profound philosophical undertones. Your analytical mind delights in decoding layered meanings while your heart remains open to the emotional resonance of each story."
    },
    "AGER" => {
      title: "The Artistic Realist",
      description: "You find beauty in the raw authenticity of cinema. While appreciating artistic excellence, you connect most deeply with stories that mirror life's genuine moments. Your viewing style combines a love for aesthetic mastery with an unwavering appreciation for emotional truth."
    },
    "AGIR" => {
      title: "The Contemplative Observer",
      description: "Your approach to cinema is both introspective and analytical. You appreciate films that offer deep psychological insights while maintaining artistic integrity. Like a skilled detective of human nature, you uncover hidden meanings in every frame."
    },
    "AGIA" => {
      title: "The Aesthetic Adventurer",
      description: "For you, cinema is a journey through visual poetry. You seek out films that combine artistic innovation with immersive storytelling. Your adventurous spirit in film appreciation leads you to discover beauty in both experimental art films and emotionally resonant narratives."
    },
    "RGEA" => {
      title: "The Emotional Voyager",
      description: "You navigate the world of cinema through your heart while appreciating its artistic depths. Your connection to films is primarily emotional, yet you have a keen eye for creative excellence. This combination makes every viewing experience a journey of both feeling and aesthetic discovery."
    },
    "RGEI" => {
      title: "The Empathetic Analyst",
      description: "Your approach to cinema balances emotional resonance with intellectual curiosity. You are drawn to films that explore the human condition through both heart and mind, finding profound meaning in stories that combine emotional depth with thoughtful analysis."
    },
    "RGER" => {
      title: "The Authentic Storyteller",
      description: "You value cinema that speaks to the heart of human experience. Your preference for emotional authenticity combined with appreciation for artistic craft makes you particularly attuned to films that tell genuine stories with creative excellence."
    }
  }

  def self.get_archetype(type_code)
    default = {
      title: "The Cinematic Explorer",
      description: "Your unique approach to cinema combines multiple perspectives, making you a versatile and nuanced film enthusiast. You appreciate both the technical mastery and emotional depth of great filmmaking, finding your own special way to connect with each story."
    }

    ARCHETYPES[type_code] || default
  end
end
