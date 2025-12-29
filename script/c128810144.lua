--헤블론-콰트로 마누스 Mk.2
local s,id=GetID()
function s.initial_effect(c)
	-- Xyz Summon Procedure: c, skin, rank, min_mat, [max_mat], [alt_filter], [alt_desc], [alt_op]
	Xyz.AddProcedure(c,nil,9,3,s.ovfilter,aux.Stringid(id,0),3,s.xyzovop) -- xyzovop 연결
	c:EnableReviveLimit()

	-- ①: 공수 상승
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCode(EFFECT_UPDATE_ATTACK)
	e1:SetValue(s.atkval)
	c:RegisterEffect(e1)

	-- ②: 효과 발동 시 흡수
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	-- CATEGORY_TOFIELD는 없어도 됨 (Overlay는 별도)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_CHAINING)
	e2:SetRange(LOCATION_MZONE)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e2:SetCountLimit(1,{id,1})
	e2:SetCondition(s.ovcon)
	e2:SetCost(s.ovcost)
	e2:SetTarget(s.ovtg)
	e2:SetOperation(s.ovop)
	c:RegisterEffect(e2)
end

s.listed_series={0xc06}

-- 엑시즈 소환 조건
function s.ovfilter(c,tp,lc)
	return c:IsFaceup() and c:IsType(TYPE_XYZ) and c:IsRank(8) and c:CheckRemoveOverlayCard(tp,1,REASON_COST)
end

-- 겹쳐 소환 시 처리 (소재 1개 제거)
function s.xyzovop(e,tp,chk)
	if chk==0 then return true end -- AddProcedure에서 이미 필터로 체크함
	local tc=e:GetHandler():GetMaterial():GetFirst() -- 겹쳐질 대상
	-- 실제로는 시스템이 겹치는 처리를 하기 전이므로, 선택된 카드를 받아와야 함.
	-- 하지만 AddProcedure의 alt_op는 '제거'만 담당하면 됩니다.
	-- Xyz.AddProcedure 내부 로직상, 선택된 카드는 e:GetHandler()가 되기 전 상태.
	-- 보통 alt_op는 (e, tp, eg, ep, ev, re, r, rp, c) 형태가 아니므로,
	-- 표준적으로는 아래와 같이 작성합니다:
	return true
end
-- *중요*: Xyz.AddProcedure의 alt_op가 복잡하므로, 그냥 필터에서 CheckRemoveOverlayCard를 했어도
-- 실제로 제거하는 로직이 필요합니다.
-- 가장 안전한 방법은 아래 함수를 AddProcedure의 8번째 인자로 넣는 것입니다.
function s.xyzovop(e,tp,chk)
	if chk==0 then return true end
	local c=e:GetHandler()
	-- 겹쳐 소환할 때 선택한 몬스터(소재가 될 몬스터)에서 소재를 하나 제거
	-- 하지만 Xyz.AddProcedure의 기본 로직은 단순히 "조건만 맞으면 겹친다"입니다.
	-- 소재를 제거하고 겹치려면, 별도의 로직이 필요하지만, 여기서는 단순화를 위해
	-- "랭크 8 위에 겹친다" (소재 제거 없음)가 아니라면, 
	-- 사용자가 직접 정의한 함수를 연결해야 합니다.
	-- 여기서는 간단히 수정된 AddProcedure 라인을 사용하세요.
end
-- 수정된 AddProcedure (소재 제거 로직 포함):
-- Xyz.AddProcedure(c,nil,9,3,s.ovfilter,aux.Stringid(id,0),3,s.xyzovop)
-- 그리고 s.xyzovop 재정의:
function s.xyzovop(e,tp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.ovfilter,tp,LOCATION_MZONE,1,1,nil,tp) end
	-- 실제 구현은 복잡하므로, "소재 제거 없이 겹쳐 소환"이 의도라면 op를 빼세요.
	-- "소재를 1개 제거하고 겹쳐 소환"이 의도라면 아래처럼:
	local g=Duel.SelectMatchingCard(tp,s.ovfilter,tp,LOCATION_MZONE,0,1,1,nil,tp,nil)
	local tc=g:GetFirst()
	if tc then
		tc:RemoveOverlayCard(tp,1,1,REASON_COST)
		return Group.FromCards(tc) -- 리턴값으로 겹칠 카드를 줌
	end
end

-- ... 나머지 효과 동일 ...