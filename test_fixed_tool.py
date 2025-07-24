#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
测试修复后的create_ppt_by_outline工具
"""
import sys
sys.path.append('.')
from main import AIPPTClient

def test_fixed_create_ppt_by_outline():
    """测试修复后的根据大纲创建PPT功能"""
    print("测试修复后的create_ppt_by_outline工具")
    print("=" * 50)
    
    # 创建客户端
    client = AIPPTClient()
    
    # 原始团日活动大纲
    outline = {
        "title": "传承雷锋精神 绿化美丽家园",
        "subTitle": "2025年3月主题团日活动部署会",
        "chapters": [
            {
                "chapterTitle": "活动背景与主题",
                "contents": [
                    "习近平总书记关于青年工作的重要指示",
                    "雷锋精神与生态文明建设双主题联动",
                    "2025年3月6日-26日全覆盖开展"
                ]
            },
            {
                "chapterTitle": "四大核心活动",
                "contents": [
                    "【雷锋精神实践】宣讲/志愿服务/文化创作",
                    "【植树环保活动】绿植领养/光盘行动",
                    "【开学第一课】融入心理健康教育",
                    "【组织生活会】对标定级与先进性评价"
                ]
            },
            {
                "chapterTitle": "实施要求",
                "contents": [
                    "3月28日前提交活动总结",
                    "文字材料500字+3-5张高清照片",
                    "横版视频(1080P/3分钟内)"
                ]
            },
            {
                "chapterTitle": "评优激励",
                "contents": [
                    "作为五四红旗团支部评选依据",
                    "十佳主题团日活动案例征集",
                    "优秀作品全校展示平台"
                ]
            }
        ]
    }
    
    try:
        # 使用修复后的方法
        result = client.create_ppt_by_outline(
            text="团委关于2025年3月主题团日活动的整体部署通知",
            outline=outline,
            template_id="202407176CA9161",
            author="学院团委",
            is_figure=True,
            ai_image="normal"
        )
        
        print("修复后的结果:")
        print(f"状态码: {result.get('code')}")
        print(f"描述: {result.get('desc')}")
        
        if result.get('code') == 0:
            print("SUCCESS 修复成功！PPT创建任务已提交")
            data = result.get('data', {})
            print(f"任务ID: {data.get('sid')}")
            print(f"封面图: {data.get('coverImgSrc')}")
            print(f"标题: {data.get('title')}")
            print(f"副标题: {data.get('subTitle')}")
        else:
            print(f"FAILED 仍然失败: {result}")
            
    except Exception as e:
        print(f"ERROR 测试异常: {e}")

if __name__ == "__main__":
    test_fixed_create_ppt_by_outline()