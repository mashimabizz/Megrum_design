import MegrumDesign
import SwiftUI

#if DEBUG
struct MeguriMapOverlay: View {
    var mode: MeguriHomeSheetMode

    var body: some View {
        ZStack {
            MeguriPinBubble(title: "物販列")
                .position(x: 238, y: mode == .normal ? 170 : 0)
                .opacity(mode == .normal ? 1 : 0)

            MeguriPinBubble(title: "会場横")
                .position(x: 96, y: mode == .normal ? 260 : 0)
                .opacity(mode == .normal ? 1 : 0)

            MeguriPinBubble(title: "駅前広場")
                .position(x: 186, y: mode == .normal ? 372 : 0)
                .opacity(mode == .normal ? 1 : 0)

            MeguriImagePin(imageName: "twice_penlight", size: mode == .normal ? 62 : 56)
                .position(x: mode == .normal ? 58 : 74, y: mode == .normal ? 345 : 148)

            MeguriImagePin(imageName: "twice_momo_1", size: 66)
                .position(x: mode == .normal ? 118 : 178, y: mode == .normal ? 158 : 86)

            MeguriImagePin(imageName: "twice_sana_1", size: mode == .normal ? 60 : 58)
                .position(x: mode == .normal ? 198 : 304, y: mode == .normal ? 292 : 134)

            MeguriImagePin(imageName: "svt_mingyu", size: 62)
                .position(x: mode == .normal ? 322 : 292, y: mode == .normal ? 215 : 108)

            if mode == .normal {
                MeguriStackedPin()
                    .position(x: 290, y: 320)
            } else {
                MeguriChatPin()
                    .position(x: 260, y: 76)
                MeguriChatPin()
                    .position(x: 330, y: 52)
            }
        }
    }
}

struct MeguriPinBubble: View {
    var title: String

    var body: some View {
        VStack(spacing: 0) {
            Text(title)
                .font(.system(size: 14, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .frame(height: 42)
                .background(MegrumTheme.lavender, in: Circle())
                .shadow(color: MegrumTheme.lavender.opacity(0.30), radius: 12, y: 7)

            Circle()
                .fill(MegrumTheme.lavender)
                .frame(width: 8, height: 8)
                .overlay(Circle().stroke(.white, lineWidth: 2))
                .offset(y: -1)
        }
    }
}

struct MeguriChatPin: View {
    var body: some View {
        VStack(spacing: 0) {
            Image(systemName: "ellipsis.message.fill")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 42, height: 42)
                .background(MegrumTheme.lavender, in: Circle())
                .overlay(Circle().stroke(.white.opacity(0.90), lineWidth: 3))
                .shadow(color: MegrumTheme.lavender.opacity(0.30), radius: 10, y: 7)

            Circle()
                .fill(MegrumTheme.lavender)
                .frame(width: 8, height: 8)
                .overlay(Circle().stroke(.white, lineWidth: 2))
                .offset(y: -1)
        }
    }
}

struct MeguriImagePin: View {
    var imageName: String
    var size: CGFloat

    var body: some View {
        VStack(spacing: 0) {
            MeguriImageCircle(imageName: imageName, size: size)
                .overlay(Circle().stroke(.white, lineWidth: 4))
                .shadow(color: MeguriDesignColors.shadow, radius: 12, y: 7)

            Circle()
                .fill(MegrumTheme.lavender)
                .frame(width: 8, height: 8)
                .overlay(Circle().stroke(.white, lineWidth: 2))
                .offset(y: -1)
        }
    }
}

struct MeguriStackedPin: View {
    var body: some View {
        ZStack {
            MeguriImageCircle(imageName: "bts_v", size: 54)
                .offset(x: -12, y: -3)
            MeguriImageCircle(imageName: "aespa_ningning", size: 54)
                .offset(x: 8, y: -8)
            Text("+7")
                .font(.system(size: 15, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.lavender)
                .frame(width: 44, height: 44)
                .background(.white.opacity(0.88), in: Circle())
                .offset(x: 10, y: 8)
        }
        .frame(width: 66, height: 66)
        .background(.white.opacity(0.62), in: Circle())
        .shadow(color: MeguriDesignColors.shadow, radius: 13, y: 7)
    }
}

struct MeguriMapControls: View {
    var body: some View {
        VStack(spacing: 12) {
            MeguriFloatingIcon(systemName: "scope")
            MeguriFloatingIcon(systemName: "location.fill")
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }
}

struct MeguriFloatingIcon: View {
    var systemName: String

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: 22, weight: .semibold, design: .rounded))
            .foregroundStyle(MegrumTheme.ink)
            .frame(width: 50, height: 50)
            .background(.white.opacity(0.94), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: MeguriDesignColors.shadow, radius: 12, y: 7)
            .accessibilityHidden(true)
    }
}
#endif
