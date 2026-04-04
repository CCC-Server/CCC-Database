-- SNo.86 H-C(히로익 챔피언) 론고미언트 아서
local s,id=GetID()
function s.initial_effect(c)
	-- 엑시즈 소환: "히로익" 레벨 4 몬스터 × 2장 이상 (최대 5장까지)
	-- 원본 No.86 규격 준수: 카드, 필터, 레벨, 최소수, 특소방법(nil), 특소설명(nil), 최대수
	Xyz.AddProcedure(c,aux.FilterBoolFunctionEx(Card.IsSetCard,0x6f),4,2,nil,nil,5)
	c:EnableReviveLimit()
	
	-- 유지비: 상대 엔드 페이즈마다 소재 1개 제거 (불가능 시 뒷면 제외)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
	e1:SetCode(EVENT_PHASE+PHASE_END)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1)
	e1:SetCondition(s.mtcon)
	e1:SetOperation(s.mtop)
	c:RegisterEffect(e1)
	
	-- ①: 소재인 "히로익" 몬스터의 수에 따른 효과 부여
	-- ● 1개 이상: 전투 내성
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_INDESTRUCTABLE_BATTLE)
	e2:SetValue(1)
	e2:SetCondition(s.effcon)
	e2:SetLabel(1)
	c:RegisterEffect(e2)
	
	-- ● 2개 이상: 공/수 1500 상승
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_SINGLE)
	e3:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCode(EFFECT_UPDATE_ATTACK)
	e3:SetValue(1500)
	e3:SetCondition(s.effcon)
	e3:SetLabel(2)
	c:RegisterEffect(e3)
	local e4=e3:Clone()
	e4:SetCode(EFFECT_UPDATE_DEFENSE)
	c:RegisterEffect(e4)
	
	-- ● 3개 이상: 완전 내성
	local e5=Effect.CreateEffect(c)
	e5:SetType(EFFECT_TYPE_SINGLE)
	e5:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e5:SetRange(LOCATION_MZONE)
	e5:SetCode(EFFECT_IMMUNE_EFFECT)
	e5:SetValue(s.efilter)
	e5:SetLabel(3)
	c:RegisterEffect(e5)
	
	-- ● 4개 이상: 상대 소환 봉쇄
	local e6=Effect.CreateEffect(c)
	e6:SetType(EFFECT_TYPE_FIELD)
	e6:SetRange(LOCATION_MZONE)
	e6:SetCode(EFFECT_CANNOT_SUMMON)
	e6:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e6:SetTargetRange(0,1)
	e6:SetCondition(s.effcon)
	e6:SetLabel(4)
	c:RegisterEffect(e6)
	local e7=e6:Clone()
	e7:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
	c:RegisterEffect(e7)
	
	-- ● 5개 이상: LP 500 이하일 때 상대 필드 클린 (퀵 효과)
	local e8=Effect.CreateEffect(c)
	e8:SetDescription(aux.Stringid(id,1))
	e8:SetCategory(CATEGORY_DESTROY)
	e8:SetType(EFFECT_TYPE_QUICK_O)
	e8:SetCode(EVENT_FREE_CHAIN)
	e8:SetRange(LOCATION_MZONE)
	e8:SetCountLimit(1)
	e8:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E)
	e8:SetCondition(s.quickcon)
	e8:SetTarget(s.destg)
	e8:SetOperation(s.desop)
	e8:SetLabel(5)
	c:RegisterEffect(e8)
end

-- "히로익" 소재 수 계산 함수
function s.get_hc_count(c)
	local og=c:GetOverlayGroup()
	if #og==0 then return 0 end
	return og:FilterCount(Card.IsSetCard,nil,0x6f)
end

-- 유지비 조건: 상대 턴 플레이어 확인
function s.mtcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetTurnPlayer()==1-tp
end

-- 유지비 처리: 소재 1개 제거, 실패 시 뒷면 제외
function s.mtop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:CheckRemoveOverlayCard(tp,1,REASON_EFFECT) then
		c:RemoveOverlayCard(tp,1,1,REASON_EFFECT)
	else
		-- 제거 불가능할 경우 뒷면 표시로 제외
		Duel.Remove(c,POS_FACEDOWN,REASON_RULE)
	end
end

-- 효과 적용 조건 판정
function s.effcon(e)
	return s.get_hc_count(e:GetHandler())>=e:GetLabel()
end

-- 완전 내성 필터
function s.efilter(e,te)
	return te:GetOwner()~=e:GetHandler() and s.effcon(e)
end

-- 5개 이상 효과용 퀵 타이밍 조건
function s.quickcon(e,tp,eg,ep,ev,re,r,rp)
	return s.effcon(e) and Duel.GetLP(tp)<=500
end

-- 파괴 효과 타겟
function s.destg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(nil,tp,0,LOCATION_ONFIELD,1,nil) end
	local g=Duel.GetMatchingGroup(nil,tp,0,LOCATION_ONFIELD,nil)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,#g,0,0)
end

-- 파괴 효과 실행
function s.desop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(nil,tp,0,LOCATION_ONFIELD,nil)
	if #g>0 then
		Duel.Destroy(g,REASON_EFFECT)
	end
end