--G.Rock 페이지-트루 스나이핑
local s,id=GetID()
function s.initial_effect(c)
	c:EnableReviveLimit()
	--정규 소환 절차 및 "전자광충-코어베이지" 참조 소재 제거 연동형 겹치기 엑시즈 소환 프로시저 구축
	Xyz.AddProcedure(c,s.pfil1,9,3,s.ovfilter,aux.Stringid(id,0),Xyz.InfiniteMats,s.xyzop)
	
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
	
	--②: 이 카드를 대상으로 하는 효과가 발동했을 때, 이 카드를 엑스트라 덱으로 되돌리고 발동한다.
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,2))
	e2:SetCategory(CATEGORY_TOEXTRA+CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_QUICK_F)
	e2:SetCode(EVENT_CHAINING)
	e2:SetRange(LOCATION_MZONE)
	e2:SetProperty(EFFECT_FLAG_DAMAGE_STEP+EFFECT_FLAG_DAMAGE_CAL)
	e2:SetCondition(s.con2)
	e2:SetCost(s.cost2) -- 엑스트라 덱 탈출을 코스트 자리에 매칭
	e2:SetTarget(s.tar2)
	e2:SetOperation(s.op2)
	c:RegisterEffect(e2)
end

-- 정규 소환 소재 필터 (레벨 9 몬스터 또는 랭크 9 몬스터)
function s.pfil1(c,xc,st,p)
	return c:IsXyzLevel(xc,9) or c:IsRank(9)
end

-- 겹치기 특수 소환 조건 필터: "G.Rock" 카드를 소재로 가진 자신 필드의 엑시즈 몬스터
function s.ovfilter(c,tp,xyzc)
	return c:IsFaceup() and c:IsType(TYPE_XYZ,xyzc,SUMMON_TYPE_XYZ,tp) and not c:IsCode(id)
		and c:GetOverlayGroup():IsExists(Card.IsSetCard,1,nil,0xfa6)
end

-- "전자광충-코어베이지" 소환 매커니즘 이식: 겹치기 소환 시 밑에 깔릴 몬스터(mc)의 엑시즈 소재를 1개 제거
function s.xyzop(e,tp,chk,mc)
	if chk==0 then return Duel.GetFlagEffect(tp,id)==0 and mc:CheckRemoveOverlayCard(tp,1,REASON_COST) end
	Duel.RegisterFlagEffect(tp,id,RESET_PHASE+PHASE_END,0,1)
	mc:RemoveOverlayCard(tp,1,1,REASON_COST)
	return true
end

-- ①번 효과 조건: 엑시즈 소환에 성공했을 경우
function s.con1(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_XYZ)
end

function s.tar1(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	local g=Duel.GetMatchingGroup(Card.IsNegatable,tp,0,LOCATION_ONFIELD,nil)
	Duel.SetOperationInfo(0,CATEGORY_DISABLE,g,#g,0,0)
	Duel.SetPossibleOperationInfo(0,CATEGORY_REMOVE,nil,1,1-tp,LOCATION_ONFIELD)
end

-- ①번 효과 오퍼레이션: "마인드 미러 포스" 일괄 무효화 및 상대 필드 앞/뒷면 가리지 않는 1장 제외
function s.op1(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local g=Duel.GetMatchingGroup(Card.IsNegatable,tp,0,LOCATION_ONFIELD,nil):Match(Card.IsCanBeDisabledByEffect,nil,e)
	
	if #g>0 then
		for nc in g:Iter() do
			nc:NegateEffects(c)
		end
		Duel.AdjustInstantly()
	end
	
	-- 실제로 1장 이상 무효화 성공했는지 확인
	local og=g:Filter(Card.IsDisabled,nil)
	if #og>0 then
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

-- ②번 효과 조건: "청빙의 백야룡" 공식 체인 추적 규격
function s.con2(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not re:IsHasProperty(EFFECT_FLAG_CARD_TARGET) then return false end
	local g=Duel.GetChainInfo(ev,CHAININFO_TARGET_CARDS)
	return g and g:IsContains(c)
end

-- ②번 효과 전용 소생 필터: 오직 타 카드군(이리스필 등) 유출을 막고 "G.Rock" 몬스터만 소생 가능하게 제한
function s.spfilter(c,e,tp)
	return c:IsSetCard(0xfa6) and c:IsType(TYPE_MONSTER) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

-- ②번 효과 코스트: "되돌리고 발동한다" 매커니즘을 위해 발동 코스트 시점에 엑스트라 덱 탈출 실행
function s.cost2(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return c:IsAbleToExtraAsCost() end
	Duel.SendtoDeck(c,nil,SEQ_DECKTOP,REASON_COST)
end

function s.tar2(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_GRAVE)
end

-- ②번 효과 오퍼레이션: 이미 코스트로 안전하게 날아갔으므로 묘지의 G.Rock 몬스터 소생만 집중 연산
function s.op2(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	-- 이리스필 소환 에러 완벽 차증 시스템 필터 가동
	if Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_GRAVE,0,1,nil,e,tp) then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.spfilter),tp,LOCATION_GRAVE,0,1,1,nil,e,tp)
		if #g>0 then
			Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
		end
	end
end