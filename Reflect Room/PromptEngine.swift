//
//  PromptEngine.swift
//  Reflect Room
//
//  Created by Andrew Lawrence on 11/08/25.
//

import Foundation

// MARK: - Prompt Mode Options
enum PromptMode {
    case local          // Free tier – local rule-based engine
    case aiOpenAI       // Premium tier – GPT-4o or GPT-4o-mini
    case aiBedrock      // Premium tier – AWS Claude / Titan via Bedrock
}

// MARK: - Prompt Engine
struct PromptEngine {
    
    /// Generates reflection prompts based on user data and selected mood.
    static func generatePrompts(from insights: [String: Any],
                                selectedMood: String?,
                                mode: PromptMode,
                                completion: @escaping ([PromptSection]) -> Void) {
        switch mode {
        case .local:
            completion(localPromptSections(from: insights, selectedMood: selectedMood))
        case .aiOpenAI:
            generateAIprompts_OpenAI(from: insights, selectedMood: selectedMood, completion: completion)
        case .aiBedrock:
            generateAIprompts_Bedrock(from: insights, selectedMood: selectedMood, completion: completion)
        }
    }
}

// MARK: - Prompt Section Model
struct PromptSection: Identifiable {
    let id = UUID()
    let title: String
    let prompts: [String]
}

// MARK: - 1️⃣ Local Prompt Logic (Free Tier)
extension PromptEngine {
    
    private static func localPromptSections(from insights: [String: Any], selectedMood: String?) -> [PromptSection] {
        var sections: [PromptSection] = []
        
        // --- Mood-Based Section
        let moodPrompts = moodSpecificPrompts(for: selectedMood)
        let shuffledMoodPrompts = Array(moodPrompts.shuffled().prefix(3))
        let moodSection = PromptSection(
            title: "Based on your mood selection",
            prompts: shuffledMoodPrompts
        )
        sections.append(moodSection)
        
        // --- Default Reflection Section
        let defaultPrompts = generalReflectionPrompts()
        let shuffledDefaults = Array(defaultPrompts.shuffled().prefix(3))
        let defaultSection = PromptSection(
            title: "Mindful Reflections",
            prompts: shuffledDefaults
        )
        sections.append(defaultSection)
        
        return sections
    }
    
    // MARK: Mood-Specific Prompts (20 Each)
    private static func moodSpecificPrompts(for mood: String?) -> [String] {
        guard let mood = mood?.lowercased() else { return generalReflectionPrompts() }
        
        switch mood {
        case "happy":
            return [
                "What has been bringing you joy lately?",
                "How can you hold onto this sense of happiness?",
                "What are you most grateful for today?",
                "Who or what made you smile recently?",
                "How do you share your happiness with others?",
                "What small moment brightened your day?",
                "What helps you maintain your positive energy?",
                "How do you know when you’re truly content?",
                "What are you celebrating about yourself?",
                "How can you savor this feeling longer?",
                "What simple pleasures make you feel alive?",
                "When did you last feel at peace?",
                "What helps you recognize your growth?",
                "What’s been a highlight of your week?",
                "How can you use this good energy tomorrow?",
                "What made you laugh recently?",
                "What song or memory lifts your spirits?",
                "How do you express gratitude when you’re happy?",
                "What reminds you that you deserve joy?",
                "What are you excited about right now?"
            ]
            
        case "sad":
            return [
                "What has been weighing on your heart?",
                "Who can you turn to for comfort?",
                "What would make today a little lighter?",
                "What helps you find peace when you feel down?",
                "What kindness can you offer yourself right now?",
                "What do you need to release to heal?",
                "How can you take care of yourself today?",
                "What has helped you through tough times before?",
                "What lesson might this sadness hold?",
                "Who reminds you that you’re not alone?",
                "What’s something small you can look forward to?",
                "How can you be gentle with yourself this week?",
                "What brings you a bit of relief when you’re low?",
                "What can you forgive yourself for?",
                "What emotion feels strongest right now?",
                "How can you make space for hope again?",
                "What helps you move forward when you’re tired?",
                "Who or what still gives you comfort?",
                "What’s something beautiful you’ve noticed recently?",
                "How can you show yourself love right now?"
            ]
            
        case "anxious":
            return [
                "What’s been making you feel uneasy lately?",
                "What helps calm your mind when you feel tense?",
                "What’s one thing you can control right now?",
                "Where in your body do you feel your anxiety?",
                "What can you let go of to find peace?",
                "What helps you ground yourself when thoughts spiral?",
                "What would you say to a friend feeling this way?",
                "What does safety mean to you right now?",
                "How can you create calm in your space today?",
                "What reassurance do you need to hear?",
                "What’s something small you can accomplish now?",
                "What reminder would help you feel steadier?",
                "What thought is worth releasing today?",
                "When was the last time you felt at ease?",
                "What do you want your body to know right now?",
                "What has helped you breathe easier before?",
                "What truth helps quiet your worries?",
                "What does stillness look like for you?",
                "How can you respond to fear with kindness?",
                "What feels safe in your world right now?"
            ]
            
        case "angry":
            return [
                "What triggered your frustration today?",
                "What is your anger protecting you from?",
                "How can you express anger safely and constructively?",
                "What boundaries need to be honored?",
                "What emotion might be beneath your anger?",
                "When was the last time you felt truly calm?",
                "What helps you release tension in your body?",
                "What situation challenged your patience recently?",
                "What are you not saying that needs to be said?",
                "What helps you reconnect with peace?",
                "What would forgiveness look like today?",
                "What’s your anger trying to teach you?",
                "Who or what are you holding onto?",
                "What helps you cool off mentally?",
                "What do you wish others understood about your feelings?",
                "How can you separate reaction from reflection?",
                "What can you change, and what must you accept?",
                "What restores your balance after anger?",
                "What boundaries do you want to reinforce?",
                "How can you move from frustration toward understanding?"
            ]
            
        default:
            return generalReflectionPrompts()
        }
    }
    
    // MARK: Default Reflection Pool (20 Prompts)
    private static func generalReflectionPrompts() -> [String] {
        return [
            "What’s been standing out to you this week?",
            "What’s something you’ve learned about yourself recently?",
            "How are you growing right now?",
            "What have you been avoiding that deserves attention?",
            "What inspired you this week?",
            "What challenge has made you stronger?",
            "What moment of peace have you experienced lately?",
            "What emotion feels loudest right now?",
            "What theme keeps showing up in your reflections?",
            "How can you show yourself grace today?",
            "What’s something you’re proud of this month?",
            "What brings you clarity when life feels chaotic?",
            "What motivates you to keep going?",
            "What does balance look like for you right now?",
            "How do you define success for yourself today?",
            "What helps you feel grounded?",
            "Who or what has supported your growth lately?",
            "What habit would you like to strengthen?",
            "What’s one change that’s improved your life?",
            "What story about yourself are you ready to rewrite?"
        ]
    }
}

//
// MARK: - 2️⃣ OpenAI GPT-4o Integration (Premium Tier)
//
extension PromptEngine {
    private static func generateAIprompts_OpenAI(from insights: [String: Any],
                                                 selectedMood: String?,
                                                 completion: @escaping ([PromptSection]) -> Void) {
        let summary = insightsSummaryText(insights)
        let moodText = selectedMood != nil ? "Current mood: \(selectedMood!). " : ""
        
        let systemPrompt = """
        You are Reflect Room, a warm and thoughtful reflection companion.
        Generate two categories of questions: 
        (1) Based on the user's current mood 
        (2) General mindfulness prompts.
        Each category should include 3 short, introspective questions (under 20 words each).
        """
        
        let userPrompt = """
        Insights summary: \(summary)
        \(moodText)
        Create two categories of reflection prompts.
        """
        
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            completion([PromptSection(title: "Error", prompts: ["Invalid API endpoint."])])
            return
        }
        
        let payload: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": userPrompt]
            ],
            "max_tokens": 300,
            "temperature": 0.8
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer YOUR_OPENAI_API_KEY_HERE", forHTTPHeaderField: "Authorization")
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload)
        
        URLSession.shared.dataTask(with: request) { data, _, error in
            guard let data = data, error == nil else {
                completion([PromptSection(title: "AI Error", prompts: ["Could not connect to AI service."])])
                return
            }
            
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let choices = json["choices"] as? [[String: Any]],
               let message = choices.first?["message"] as? [String: Any],
               let content = message["content"] as? String {
                
                let sections = [
                    PromptSection(title: "Based on your mood selection", prompts: Array(content.components(separatedBy: "\n").filter { !$0.isEmpty }.prefix(3))),
                    PromptSection(title: "Mindful Reflections", prompts: Array(content.components(separatedBy: "\n").filter { !$0.isEmpty }.suffix(3)))
                ]
                
                completion(sections)
            } else {
                completion([PromptSection(title: "AI Response", prompts: ["No valid AI response received."])])
            }
        }.resume()
    }
}

//
// MARK: - 3️⃣ AWS Bedrock Integration (Claude / Titan)
//
extension PromptEngine {
    private static func generateAIprompts_Bedrock(from insights: [String: Any],
                                                  selectedMood: String?,
                                                  completion: @escaping ([PromptSection]) -> Void) {
        let sections = [
            PromptSection(title: "Based on your mood selection", prompts: [
                "What emotion feels strongest today?",
                "What thought do you want to let go of?",
                "What helps you feel safe right now?"
            ]),
            PromptSection(title: "Mindful Reflections", prompts: [
                "What have you learned from your reflections this week?",
                "What brings you stillness in busy times?",
                "How can you honor your current season of life?"
            ])
        ]
        completion(sections)
    }
}

//
// MARK: - Utility Helpers
//
extension PromptEngine {
    private static func insightsSummaryText(_ insights: [String: Any]) -> String {
        var summary = ""
        if let mood = insights["dominantMood"] as? String {
            summary += "Dominant mood: \(mood). "
        }
        if let avg = insights["averageMoodScore"] as? Double {
            summary += "Average mood score: \(String(format: "%.1f", avg)). "
        }
        if let streak = insights["currentStreak"] as? Int {
            summary += "Reflection streak: \(streak) days. "
        }
        if let change = insights["moodTrendPercent"] as? Double {
            summary += "Mood trend change: \(String(format: "%.1f", change))%. "
        }
        if let text = insights["recentReflectionText"] as? String, !text.isEmpty {
            summary += "Recent reflection: \(text.prefix(150))"
        }
        return summary
    }
}
