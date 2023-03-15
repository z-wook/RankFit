//
//  OnboardingMessage.swift
//  RankFit
//
//  Created by 한지욱 on 2022/12/11.
//

import Foundation

struct OnboardingMessage {
    let imageName: String
    let title: String
    let description: String
}

extension OnboardingMessage {
    static let messages: [OnboardingMessage] = [
        OnboardingMessage(imageName: "onboarding_muscle", title: "환영합니다", description: "랭크핏에 오신 것을 환영합니다.\n지금 참여하여 운동을 시작하세요."),
        OnboardingMessage(imageName: "onboarding_run", title: "목표를 달성하세요", description: "의지가 부족하신가요? 다른 사람들과 경쟁하며, 운동 의지를 높이고 목표를 달성하세요."),
        OnboardingMessage(imageName: "onboarding_yoga", title: "달라진 나를 느껴보세요", description: "운동을 통해 삶의 균형을 맞추어 건강을 얻으세요. 당신의 몸은 보답할 것입니다.")
    ]
}
