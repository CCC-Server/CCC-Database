--G.Rock 페이지-트루 스나이핑
local s,id=GetID()
function s.initial_effect(c)
	c:EnableReviveLimit()
	--정규 소환 절차 및 "진의 고독훼귀-하마" 참조 겹치기 엑시즈 소환 룰
	Xyz.AddProcedure(c,s.pfil1,9,3,s.ovfilter,aux.Stringid(id,0),Xyz.InfiniteMats,s.ovop)
	
	--①: 이 카드를 엑시즈 소환했을 경우에 발동한다. (강제 유발 효과)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,1))
	e1:SetCategory(CATEGORY_DISABLE+CATEGORY_REMOVE)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetCondition(s.con1)
	e1:SetTarget(s.tar1)
	e1:SetOperation(s.op1)
	c:RegisterEffect(e1)
	
	--②: 이 카드를 대상으로 하는 효과가 발동했을 때 발동한다. ("청빙의 백야룡" 공식 체인 추적 규격 반영 및 강제 발동)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,2))
	e2:SetCategory(CATEGORY_TOEXTRA+CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_QUICK_F)
	e2:SetCode(EVENT_CHAINING)
	e2:SetRange(LOCATION_MZONE)
	e2:SetProperty(EFFECT_FLAG_DAMAGE_STEP+EFFECT_FLAG_DAMAGE_CAL)
	e2:SetCondition(s.con2)
	e2:SetTarget(s.tar2)
	e2:SetOperation(s.op2)
	c:RegisterEffect(e2)
end

-- 정규 소환 소재 필터 (레벨 9 몬스터 또는 랭크 9 몬스터)
function s.pfil1(c,xc,st,p)
	return c:IsXyzLevel(xc,9) or c:IsRank(9)
end

-- "진의 고독훼귀-하마" 공식 소환 방식 참조 기동 필터
function s.ovfilter(c,tp,lc)
	return c:IsFaceup() and c:IsCanBeXyzMaterial() and c:IsControler(tp) and not c:IsCode(id)
		and c:GetOverlayGroup():IsExists(Card.IsSetCard,1,nil,0xfa6)
end

-- 겹치기 전용 명칭 턴제 플래그 체크 프로시저
function s.ovop(e,tp,chk)
	if chk==0 then return Duel.GetFlagEffect(tp,id)==0 end
	Duel.RegisterFlagEffect(tp,id,RESET_PHASE+PHASE_END,0,1)
	return true
end

-- ①번 효과 조건: 엑시즈 소환에 성공했을 경우
function s.con1(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_XYZ)
end

function s.tar1(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	-- "마인드 미러 포스" 무효화 타겟팅 필터 이식
	local g=Duel.GetMatchingGroup(Card.IsNegatable,tp,0,LOCATION_ONFIELD,nil)
	Duel.SetOperationInfo(0,CATEGORY_DISABLE,g,#g,0,0)
	Duel.SetPossibleOperationInfo(0,CATEGORY_REMOVE,nil,1,1-tp,LOCATION_ONFIELD)
end

-- ①번 효과 오퍼레이션: "마인드 미러 포스" 최신 무효화 연산 시스템 도입
function s.op1(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	-- 1. 상대 필드의 '앞면 표시' 무효화 가능 카드를 전원 수집
	local g=Duel.GetMatchingGroup(Card.IsNegatable,tp,0,LOCATION_ONFIELD,nil):Match(Card.IsCanBeDisabledByEffect,nil,e)
	
	-- 마인드 미러 포스식 일괄 무효화 처리
	if #g>0 then
		for nc in g:Iter() do
			nc:NegateEffects(c)
		end
		-- 엔진이 무효화 상태를 실시간 데이터베이스에 즉시 반영하도록 갱신 명령
		Duel.AdjustInstantly()
	end
	
	-- 2. 실제로 1장 이상이 정상적으로 무효화 처리에 성공했는지 그룹 필터로 정밀 검증
	local og=g:Filter(Card.IsDisabled,nil)
	if #og>0 then
		-- 3. 성공했다면 상대 필드의 카드 1장 제외 (제외 구역은 앞면/뒷면 포함 상대 필드 전체)
		if Duel.IsExistingMatchingCard(Card.IsAbleToRemove,tp,0,LOCATION_ONFIELD,1,nil) then
			Duel.BreakEffect()
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
			local rg=Duel.SelectMatchingCard(tp,Card.IsAbleToRemove,tp,0,LOCATION_ONFIELD,1,1,nil)
			if #rg>0 then
				Duel.Remove(rg,POS_FACEUP,REASON_EFFECT)
			end
		end
	end
end

-- ②번 효과 조건: "청빙의 백야룡" 공식 엔진 가이드 이식
function s.con2(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not re:IsHasProperty(EFFECT_FLAG_CARD_TARGET) then return false end
	local g=Duel.GetChainInfo(ev,CHAININFO_TARGET_CARDS)
	return g and g:IsContains(c)
end

function s.tar2(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_TOEXTRA,e:GetHandler(),1,0,0)
	Duel.SetPossibleOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_GRAVE)
end

-- ②번 효과 오퍼레이션
function s.op2(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) and c:IsFaceup() and Duel.SendtoDeck(c,nil,SEQ_DECKTOP,REASON_EFFECT)>0 and c:IsLocation(LOCATION_EXTRA) then
		if Duel.GetLocationCount(tp,LOCATION_MZONE)>0 and Duel.IsExistingMatchingCard(Card.IsCanBeSpecialSummoned,tp,LOCATION_GRAVE,0,1,nil,e,0,tp,false,false) then
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
			local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(Card.IsCanBeSpecialSummoned),tp,LOCATION_GRAVE,0,1,1,nil,e,0,tp,false,false)
			if #g>0 then
				Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
			end
		end
	end
end