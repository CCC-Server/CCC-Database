--제 9사도-건설자 루크 엑스 루체 칼리고
local s,id=GetID()
function s.initial_effect(c)
	-- 엑시즈 소환: 레벨 13 몬스터 x5 / 자신 필드의 "제 9사도-건설자 루크" 위에 겹쳐서도 가능
	c:EnableReviveLimit()
	Xyz.AddProcedure(c,nil,13,5,s.ovfilter,aux.Stringid(id,0))

	-- 룰상 "헤블론" 카드로도 취급한다
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
	e0:SetCode(EFFECT_ADD_CODE)
	e0:SetValue(0xc06)
	c:RegisterEffect(e0)

	-- ①: 자신 필드의 카드는 상대의 효과의 대상이 되지 않는다
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
	e1:SetRange(LOCATION_MZONE)
	e1:SetTargetRange(LOCATION_ONFIELD,0)
	e1:SetValue(aux.tgoval)
	c:RegisterEffect(e1)

	-- ②: 엑시즈 소재 1개당 공/수 500 상승
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_UPDATE_ATTACK)
	e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e2:SetRange(LOCATION_MZONE)
	e2:SetValue(s.atkval)
	c:RegisterEffect(e2)
	local e3=e2:Clone()
	e3:SetCode(EFFECT_UPDATE_DEFENSE)
	c:RegisterEffect(e3)

	-- ③: 상대 몬스터 효과 발동시, 소재 4개 제거 -> 그 몬스터를 소재로 하고 상대 드로우
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,1))
	e4:SetCategory(CATEGORY_DRAW)
	e4:SetType(EFFECT_TYPE_QUICK_O)
	e4:SetCode(EVENT_CHAINING)
	e4:SetRange(LOCATION_MZONE)
	e4:SetCondition(s.xyzcon)
	e4:SetCost(s.xyzcost)
	e4:SetTarget(s.xyztg)
	e4:SetOperation(s.xyzop)
	c:RegisterEffect(e4)
end

-- 대체 엑시즈 소재: 자신 필드의 앞면 "제 9사도-건설자 루크"
function s.ovfilter(c,tp,xyzc)
	return c:IsFaceup() and c:IsCode(128810143)
end

-- ②
function s.atkval(e,c)
	return c:GetOverlayCount()*500
end

-- ③
function s.xyzcon(e,tp,eg,ep,ev,re,r,rp)
	return rp==1-tp and re:IsActiveType(TYPE_MONSTER)
end
function s.xyzcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return c:CheckRemoveOverlayCard(tp,4,REASON_COST) end
	c:RemoveOverlayCard(tp,4,4,REASON_COST)
end
function s.xyztg(e,tp,eg,ep,ev,re,r,rp,chk)
	local rc=re:GetHandler()
	if chk==0 then return rc:IsCanBeXyzMaterial(e:GetHandler(),tp,REASON_EFFECT)
		and Duel.IsPlayerCanDraw(1-tp,1) end
	Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,0,1-tp,1)
end
function s.xyzop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local rc=re:GetHandler()
	if not c:IsRelateToEffect(e) or c:IsFacedown() then return end
	if not rc:IsRelateToEffect(re) or rc:IsImmuneToEffect(e) then return end
	rc:CancelToGrave()
	Duel.Overlay(c,rc,true)
	if rc:IsLocation(LOCATION_OVERLAY) then
		Duel.BreakEffect()
		Duel.Draw(1-tp,1,REASON_EFFECT)
	end
end