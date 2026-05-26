--코스모 핀드-중력의 바이스
local s,id=GetID()
function s.initial_effect(c)
	c:EnableReviveLimit()
	
	-- 융합 소환 설정: 공격력과 수비력이 0인 악마족 ×2
	Fusion.AddProcMixN(c,true,true,s.ffilter,2)
	Fusion.AddContactProc(c,s.contactfil,s.contactop,s.splimit)

	-- 이 카드는 효과로는 파괴되지 않는다 (E1)
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
	e1:SetValue(1)
	c:RegisterEffect(e1)

	-- 상대 필드의 앞면 표시 몬스터 제외 (E2)
	local e2=Effect.CreateEffect(c)
	e2:SetCategory(CATEGORY_REMOVE)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,id)
	e2:SetTarget(s.rmtg)
	e2:SetOperation(s.rmop)
	c:RegisterEffect(e2)
end

s.listed_series={0xc04}

-- 융합 소재 필터: 공격력과 수비력이 0인 악마족
function s.ffilter(c)
	return c:IsRace(RACE_FIEND) and c:IsAttack(0) and c:IsDefense(0)
end

-- 🔹 컨택트 융합 관련 함수 🔹
-- 융합 재료 필터 (공/수 0인 악마족 몬스터)
function s.contactfil(tp)
	return Duel.GetMatchingGroup(s.matfilter, tp, LOCATION_GRAVE, 0, nil)
end

function s.matfilter(c)
	return c:IsRace(RACE_FIEND) and c:IsAttack(0) and c:IsDefense(0) and c:IsAbleToRemoveAsCost()
end

-- 융합 재료 제외 처리
function s.contactop(g,tp)
	Duel.Remove(g, POS_FACEUP, REASON_COST+REASON_MATERIAL+REASON_FUSION)
end

-- 필드의 몬스터를 융합 재료로 사용하지 않도록 제한
function s.contactlim(e,c)
	return c:IsLocation(LOCATION_GRAVE)
end

-- 융합 가능 조건 (묘지에 필요한 수의 재료가 있는지 확인)
function s.contactcon(e,tp)
	return Duel.IsExistingMatchingCard(s.matfilter, tp, LOCATION_GRAVE, 0, 2, nil)
end

-- 제외 효과 타겟 설정 (E2)
function s.rmtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(1-tp) and chkc:IsFaceup() and chkc:IsAbleToRemove() end
	if chk==0 then return Duel.IsExistingTarget(Card.IsAbleToRemove,tp,0,LOCATION_MZONE,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local g=Duel.SelectTarget(tp,Card.IsAbleToRemove,tp,0,LOCATION_MZONE,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,g,1,0,0)
end

-- 제외 효과 실행 (E2)
function s.rmop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) then
		Duel.Remove(tc,POS_FACEUP,REASON_EFFECT)
	end
end