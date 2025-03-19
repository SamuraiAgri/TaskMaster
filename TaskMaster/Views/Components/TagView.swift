import SwiftUI

struct TagView: View {
    var tag: Tag
    var isCompact: Bool = false
    var onRemove: (() -> Void)? = nil
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.xxs) {
            Circle()
                .fill(tag.color)
                .frame(width: 8, height: 8)
            
            Text(tag.name)
                .font(DesignSystem.Typography.font(
                    size: isCompact ? DesignSystem.Typography.caption2 : DesignSystem.Typography.caption1
                ))
                .foregroundColor(tag.color.darker())
                .lineLimit(1)
            
            // 削除ボタン（オプション）
            if let onRemove = onRemove {
                Button(action: onRemove) {
                    Image(systemName: "xmark")
                        .font(.system(size: isCompact ? 8 : 10))
                        .foregroundColor(tag.color.darker())
                }
                .padding(.leading, -4)
            }
        }
        .padding(.horizontal, isCompact ? DesignSystem.Spacing.xs : DesignSystem.Spacing.s)
        .padding(.vertical, isCompact ? 2 : DesignSystem.Spacing.xxs)
        .background(tag.color.opacity(0.2))
        .cornerRadius(DesignSystem.CornerRadius.small)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                .stroke(tag.color.opacity(0.5), lineWidth: 1)
        )
    }
}

// 複数タグの表示コンポーネント
struct TagsListView: View {
    var tags: [Tag]
    var isCompact: Bool = false
    var limit: Int? = nil
    var onRemove: ((UUID) -> Void)? = nil
    
    var body: some View {
        // タグを表示する数制限
        let displayTags = limit != nil ? Array(tags.prefix(limit!)) : tags
        let hasMore = limit != nil && tags.count > limit!
        
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DesignSystem.Spacing.xs) {
                ForEach(displayTags) { tag in
                    TagView(
                        tag: tag,
                        isCompact: isCompact,
                        onRemove: onRemove != nil ? { onRemove!(tag.id) } : nil
                    )
                }
                
                // 「+n」表示
                if hasMore {
                    Text("+\(tags.count - limit!)")
                        .font(DesignSystem.Typography.font(
                            size: isCompact ? DesignSystem.Typography.caption2 : DesignSystem.Typography.caption1
                        ))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .padding(.horizontal, isCompact ? DesignSystem.Spacing.xs : DesignSystem.Spacing.s)
                        .padding(.vertical, isCompact ? 2 : DesignSystem.Spacing.xxs)
                        .background(DesignSystem.Colors.background)
                        .cornerRadius(DesignSystem.CornerRadius.small)
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                                .stroke(DesignSystem.Colors.textSecondary.opacity(0.5), lineWidth: 1)
                        )
                }
            }
            .padding(.vertical, DesignSystem.Spacing.xxs)
        }
    }
}

// タグセレクターコンポーネント
struct TagSelectorView: View {
    var tags: [Tag]
    @Binding var selectedTagIds: [UUID]
    var isCompact: Bool = false
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DesignSystem.Spacing.xs) {
                ForEach(tags) { tag in
                    let isSelected = selectedTagIds.contains(tag.id)
                    
                    Button(action: {
                        if isSelected {
                            selectedTagIds.removeAll(where: { $0 == tag.id })
                        } else {
                            selectedTagIds.append(tag.id)
                        }
                    }) {
                        HStack(spacing: DesignSystem.Spacing.xxs) {
                            Circle()
                                .fill(tag.color)
                                .frame(width: 8, height: 8)
                            
                            Text(tag.name)
                                .font(DesignSystem.Typography.font(
                                    size: isCompact ? DesignSystem.Typography.caption2 : DesignSystem.Typography.caption1
                                ))
                                .foregroundColor(isSelected ? .white : tag.color.darker())
                                .lineLimit(1)
                        }
                        .padding(.horizontal, isCompact ? DesignSystem.Spacing.xs : DesignSystem.Spacing.s)
                        .padding(.vertical, isCompact ? 2 : DesignSystem.Spacing.xxs)
                        .background(isSelected ? tag.color : tag.color.opacity(0.2))
                        .cornerRadius(DesignSystem.CornerRadius.small)
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                                .stroke(tag.color.opacity(0.5), lineWidth: 1)
                        )
                    }
                }
            }
            .padding(.vertical, DesignSystem.Spacing.xxs)
        }
    }
}

// プレビュー
struct TagView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // 通常のタグ
            TagView(tag: Tag.samples[0])
            
            // コンパクトなタグ
            TagView(tag: Tag.samples[1], isCompact: true)
            
            // 削除可能なタグ
            TagView(tag: Tag.samples[2], onRemove: {})
            
            // タグリスト
            TagsListView(tags: Tag.samples, limit: 5)
            
            // タグセレクター
            TagSelectorView(tags: Tag.samples, selectedTagIds: .constant([Tag.samples[0].id, Tag.samples[2].id]))
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
