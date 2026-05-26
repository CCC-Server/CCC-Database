--코스모 핀드-공간조약자 가우니스
-- 코스모 핀드 - 공간조약자 가우니스
local s,id=GetID()
function s.initial_effect(c)
	-- Xyz Summon procedure
	Xyz.AddProcedure(c,aux.FilterBoolFunctionEx(Card.IsRace,RACE_FIEND),12,2,s.ovfilter,aux.Stringid(id,0))
	c:EnableReviveLimit()
	
	-- Unaffected by Spell/Trap effects
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_IMMUNE_EFFECT)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetRange(LOCATION_MZONE)
	e1:SetValue(s.immval)
	c:RegisterEffect(e1)
	
	-- Banish 1 card
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_REMOVE)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,id)
	e2:SetCost(s.rmcost)
	e2:SetTarget(s.rmtg)
	e2:SetOperation(s.rmop)
	c:RegisterEffect(e2)
end

s.listed_series={0xc04} -- "코스모 핀드" 카드군

-- 엑시즈 소환 조건: 랭크 10 악마족 엑시즈 몬스터 위에 겹쳐 소환 가능
function s.ovfilter(c,tp,lc)
	return c:IsFaceup() and c:IsRace(RACE_FIEND) and c:IsRank(10) and c:IsType(TYPE_XYZ)
end

-- 이 카드는 마법/함정 카드의 효과를 받지 않음
function s.immval(e,te)
	return te:IsActiveType(TYPE_SPELL+TYPE_TRAP) and te:GetOwnerPlayer()~=e:GetHandlerPlayer() and te:IsActivated()
end

-- 엑시즈 소재를 제거하는 비용
function s.rmcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():CheckRemoveOverlayCard(tp,2,REASON_COST) end
	e:GetHandler():RemoveOverlayCard(tp,2,2,REASON_COST)
end

-- 제외 대상 지정
function s.rmtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chk==0 then return Duel.IsExistingMatchingCard(aux.TRUE,tp,0,LOCATION_ONFIELD,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local g=Duel.SelectTarget(tp,aux.TRUE,tp,0,LOCATION_ONFIELD,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,g,1,0,0)
end

-- 제외 효과 실행
function s.rmop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) then
		Duel.Remove(tc,POS_FACEUP,REASON_EFFECT)
	end
end